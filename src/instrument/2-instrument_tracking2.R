# SECOND APPOACH (Appendix B, section E)
setwd('/Users/rodrigo/Documents/tfg/')
library(raster)
library(sf)
library(dplyr)
library(plm)
library(ggplot2)

ups_3395 = st_read('data/ups/tracking-centroid/ups_3395.gpkg') %>%
  st_transform(3395)

ups_3395 = ups_3395 %>%
  mutate(areakm2 = as.numeric(st_area(ups_3395$geom)) * 1e-06)

grlist = vector('list')
for(r in unique(ups_3395$subregn)){
  data = ups_3395[ups_3395$subregn == r ,]
  fit = lm(log(areakm2) ~ year + as.factor(id) -1, data = data)
  predarea = exp(predict(fit))
  data$predarea = predarea
  
  # same rate of change for every city (take first city 1007)
  df_temp = data[1:21,] %>% st_drop_geometry()
  parea = df_temp$predarea
  nyears = length(parea)
  gr = ((parea[nyears] / parea[1])**(1/nyears) - 1)*100 
  grlist[[r]] = gr
}


#fit = lm(log(areakm2) ~ year + as.factor(id) -1, data = ups_3395)
#predarea = exp(predict(fit))
#ups_3395$predarea = predarea
#
## same rate of change for every city (take first city 1007)
#df_temp = ups_3395 %>% filter(id == 7) %>% st_drop_geometry()
#parea = df_temp$predarea
#nyears = length(parea)
#gr = ((parea[nyears] / parea[1])**(1/nyears) - 1)*100 

# tracking1: 5.83%

# tracking2: 9.52%
# Africa: 10.71%
# Asia: 9.03 %
# India: 4.73%
# "SA 5.67365712178334"
# "NAF 13.7769206772486"
# "CAF 6.09121944275599"
# "WAF 5.67864392329855"
# "SAF 6.94138291554993"
# "SEA 12.3224291094525"
# "EAF 6.86263237743796"
# "EA 12.1855510352123"
# "CA 2.60582386480388"

# create minimum bounding circles and get the radius
df_mbc = ups_3395 %>%
  select(id, year, subregn) %>%
  group_by(id) %>%
  mutate(mbc92 = lwgeom::st_minimum_bounding_circle(geom[1]),
         areambc92 = as.numeric(st_area(mbc92)) * 1e-06,
         radiusmbc92 = sqrt(areambc92/pi)) %>% 
  st_drop_geometry() 


# find the growth rate (split and lapply)
r_subregn = split(df_mbc, df_mbc$subregn)

radiusfun = function(df, gr){
  r = c(df$radiusmbc92)
  diffr = c()
  nyears = 21
  for(i in 1:nyears) {
    r_t = r[i]*((gr/100) + 1)
    r[i + 1] =  r_t
  }
  for(i in 1:nyears) {
    diff = r[i] - r[1]
    diffr[i] = diff
  }
  return(diffr)
}

final =  NA
for (i in 1:length(grlist)) {
  r_ids = split(r_subregn[[i]], r_subregn[[i]]$id)
  subregn = as.character(r_subregn[[i]]$subregn[1])
  print(subregn)
  r = c(r_subregn[[i]]$radiusmbc92)
  gr = grlist[[subregn]]

  radius_diff = as.data.frame(sapply(r_ids, radiusfun, gr))
  final = cbind(final, radius_diff)
}

# remove first one (NA)
final[,1] = NULL

# reshape to long format
radius_df = reshape(final,
                idvar     = "year",
                varying   = colnames(final),
                v.names   = c("radius"),
                times     = colnames(final),
                timevar   = 'id',
                direction = "long") %>%
  mutate(year = year + 1991) 

radius_df$id = as.numeric(radius_df$id)
radius_df = radius_df[order(radius_df$id),]
rownames(radius_df) = NULL

# append diff radius to df_mbc and create concentric circles
df_mbc$radius_diff = radius_df$radius
df_mbc = df_mbc %>%
  mutate(ccircles = st_buffer(mbc92, dist = radius_diff * 1000))

############################################################
############################################################

path_dev.land = 'data/raster/dev.land/africa_asia_15.tif'
dev.land = raster::raster(path_dev.land)
dev.land = raster::calc(dev.land, fun = function(x) {ifelse(x == 0, NA , x)})

# create potential footprint with the concentric circles
df_cc = st_set_geometry(df_mbc, df_mbc$ccircles)  %>%
  select(id, year)
ncircles = nrow(df_cc)
df_cc$pf = st_sfc(lapply(1:ncircles, function(x) st_polygon()))

for (i in 1:ncircles){
  if(i %% 200 == 0) print(i)
  
  clip1 = raster::crop(dev.land, df_cc[i, ])
  clip2 = raster::mask(clip1, df_cc[i, ])
  #plot(clip2)
  if(is.na(minValue(clip2))){
    print("length = 0, no potential footprint")
    df_cc$pf[i] = NA
    next
  } 
  
  
  # polygonize (very fast: 300x rastertoPolygons)
  # trycatch: https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
  p_footprint = tryCatch(
    expr = {
      stars::st_as_stars(clip2) %>% st_as_sf(merge = TRUE)
    },
    error = function(e){ 
      # Do this if an error is caught...
      print('cannot polygonize with stars')
      rasterToPolygons(clip2) %>% st_as_sf()
    }
  )
  
  if(length(p_footprint$geometry) == 0) {
    print("length = 0, no potential footprint")
    df_cc$pf[i] = NA
    next
  }
  
  idmax = which.max(st_area(p_footprint))
  maxareapol = p_footprint$geometry[idmax]
  #plot(maxareapol)
  df_cc$pf[i] = st_sfc(maxareapol)
}

df_ccircles = df_cc %>%
  dplyr::select(id, year, mbc92)

df_pfootprint = df_cc %>%
  st_drop_geometry() %>%
  st_as_sf() %>%
  select(id, year, pf)

attr(st_geometry(df_pfootprint), "bbox") = st_bbox(df_cc)
df_pfootprint = df_pfootprint %>% st_set_crs(3395)


st_write(df_ccircles,   dsn = 'data/ups/tracking-centroid/cc_ups_3395.gpkg', append = FALSE)
st_write(df_pfootprint,   dsn = 'data/ups/tracking-centroid/pf_ups_3395.gpkg', append = FALSE)
st_write(df_pfootprint,   dsn = 'data/ups/tracking-centroid/pf_ups_3395.shp', append = FALSE)









