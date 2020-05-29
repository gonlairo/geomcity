library(sf)
library(raster)
library(dplyr)
library(stringr)

# 1: developable land
# 2: model of city expansion: compute the radius 
# 3: potential footprint: largest contiguous patch of developable land

#######################################################
################# DEVELOPABLE LAND ###################
#######################################################

path_gdem = '/Users/rodrigo/Documents/tfg/data/data-raw/ASTER/gdem_v3/africa-asia/output/slope_gdem_mercator.tif'
path_water = '/Users/rodrigo/Documents/tfg/data/data-raw/ASTER/water_v1/africa-asia/output/output_water_mercator.tif'

water = raster(path_water)
gdem = raster(path_gdem)

slope_threshold = 20
stack = raster::stack(water, gdem)
developable_land = raster::overlay(stack,
                                   fun = function(x, y) {ifelse((x > 0) | (y > slope_threshold), 0, 1) })
writeRaster(developable_land, filename = '/Users/rodrigo/Documents/tfg/data/raster/dev.land/africa_asia_20.tif')


#######################################################
############# MODEL OF CITY EXPANSION #################
#######################################################

# Two approaches: section 5.1 and appendix B.E
# if the city’s population continued to grow as it did between 1975 and 1990 and population density
# remained constant at its 1990 level, what would be the area occupied by the city in year t? 

path_ucdb = '/Users/rodrigo/Documents/tfg/data/data-raw/GHSL/ucdb/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0.shp'
path_country_codes = '/Users/rodrigo/Documents/tfg/data/data-raw/shapefiles/asia_africa.csv'

ucdb = st_read(path_ucdb)
country_codes = read.csv(path_country_codes)

ups = st_read('/Users/rodrigo/Documents/tfg/data/ups/ups_4326.shp') %>%
  filter(!str_detect(city, 'N/A')) %>%
  mutate(area = as.numeric(st_area(geometry))*1e-6)

ucdb_radii = ucdb %>%
            filter(CTR_MN_ISO %in% country_codes$id) %>%
            dplyr::select(CTR_MN_ISO, UC_NM_MN, 
                   P75, P90, P00, B75, B90, B00) %>%
            mutate(density90 = P90 / B90) %>%
            rename(city = UC_NM_MN) %>%
            #st_drop_geometry() %>%
            mutate(pop_gr = (((P90/P75) ** (1/15)) - 1)) %>%
            na.omit() 

ucdb_radii = ucdb_radii[!duplicated(ucdb_radii$city) ,]
unique_cn_ups = as.character(unique(ups$city))
ucdb_radii_ups = ucdb_radii[ucdb_radii$city %in% unique_cn_ups ,]

lproj = vector('list')
years = c()
for (t in 2:22) {
  year = as.character(1990 + t)
  lproj[[year]] = ucdb_radii_ups$P90 * ((1 + ucdb_radii_ups$pop_gr) ** t)
  years = c(years, year)
}

df_r = as.data.frame(matrix(unlist(lproj), ncol = length(lproj)))
colnames(df_r) = years
df_r$density90 = ucdb_radii_ups$density90
df_r$city = ucdb_radii_ups$city

df_rr = reshape(df_r,
                #idvar     = "id",
                varying   = colnames(df_r)[1:(ncol(df_r) - 2)],
                v.names   = c("pop"),
                times     = colnames(df_r)[1:(ncol(df_r) - 2)],
                timevar   = 'year',
                direction = "long")

df_rr_ordered = df_rr[order(df_rr$id),]
rownames(df_rr_ordered) = NULL

# join and order: 1805 unique cities.
final = inner_join(ups, df_rr_ordered, by = c('city', 'year')) #%>% st_drop_geometry()
final$year = as.factor(final$year)
final$city = as.factor(final$city)

# P75 is 0, gr is infinite, and therfore pop is infinite
final = final[!final$pop == Inf ,]        # 3 cities
final = final[!final$density90 == Inf, ]  # 1 city

# FIRST APPROACH
# ln(area c,t) = alpha * log(pop_proj c,t) + beta * density1990 + fixed effects time + error c,t
fit = lm(formula = log(area) ~ log(pop) + log(density90) + year - 1, data = final)
summary(fit)
coef  = coefficients(fit)       # coefficients
resid = residuals(fit)          # residuals
pred  = predict(fit)            # fitted values
rsq   = summary(fit)$r.squared  # R-sq for the fit
se    = summary(fit)$sigma      # se of the fit

# get the radius: sqrt( predicted area / pi)
radius = sqrt(pred / pi)
final$radius = radius


# SECOND APPOACH
#log(area c,t) = fiexed effects city + fixed effects time + error c,t
fit2 = lm(formula = log(area) ~ city + year -1, data = final)

summary(fit2)
coef  = coefficients(fit2)       # coefficients
resid = residuals(fit2)          # residuals
pred  = predict(fit2)            # fitted values
rsq   = summary(fit2)$r.squared  # R-sq for the fit
se    = summary(fit2)$sigma      # se of the fit

radius2 = sqrt(pred / pi)
final$radius2 = radius2
final$id.y = NULL
st_write(final, "/Users/rodrigo/Documents/tfg/data/ups/all_radius.shp")

#######################################################
#############  POTENTIAL FOOTPRINTS ##################
#######################################################

# radius of 1992 = 0

path_dev.land = '/Users/rodrigo/Documents/tfg/data/raster/dev.land/africa_asia_15.tif'
path_ups      = '/Users/rodrigo/Documents/tfg/data/ups/all_radius.shp'

dev.land = raster::raster(path_dev.land)
dev.land = raster::calc(dev.land, fun = function(x) {ifelse(x == 0, NA , x)})

# I thiknk I am doing it with radius2
ups = st_read(path_ups) %>%
  mutate(radius = ifelse(year == 1992, 0, radius),
         cumsum_r = ave(radius, id_x, FUN = cumsum)) %>%
  st_transform(crs = crs(dev.land))

# mimimum bounding circle of year 1992 per each id (city)
df_circles = ups %>%
  group_by(id_x) %>%
  mutate(mbcircle92 = lwgeom::st_minimum_bounding_circle(geometry[1]),
         # create concentric circles with projected radius
         ccircles = st_buffer(mbcircle92, dist = cumsum_r * 1000))
          # is the radius actually in km????????????????????

#load("/Users/rodrigo/Documents/tfg/data/instrumentdata.RData") # ups + dev.land + df_circles_pf
df_circles = st_set_geometry(df_circles, df_circles$ccircles) 

# create potential footprint with the concentric circles calculated before.
ncircles = nrow(df_circles)
df_circles$p_footprint = st_sfc(lapply(1:ncircles, function(x) st_polygon()))
for (i in 1:ncircles){
  print(i)
  circle = df_circles$mbcircle92[i] %>% st_sf()
  clip1 = raster::crop(dev.land, df_circles[i, ])
  clip2 = raster::mask(clip1, df_circles[i, ])

  # polygonize (very fast: 300x rastertoPolygons)
  p_footprint <- stars::st_as_stars(clip2) %>% 
                 st_as_sf(merge = TRUE)
  idmax = which.max(st_area(p_footprint))
  maxareapol = p_footprint$geometry[idmax]
  #plot(maxareapol)
  df_circles$p_footprint[i] = st_sfc(maxareapol)
}

df_ccircles = st_set_geometry(df_circles, df_circles$ccircles)
df_pfootprint = st_set_geometry(df_circles, df_circles$p_footprint)
st_write(df_ccircles,   dsn = '/Users/rodrigo/Documents/tfg/data/ups/ccircles.shp')
st_write(df_pfootprint, dsn =  '/Users/rodrigo/Documents/tfg/data/ups/potential_footprints.shp')