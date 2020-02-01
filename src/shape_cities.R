library(sf)
library(dplyr)
library(tidyr)
library(raster)

shp_path = "/Users/rodrigo/Documents/tfg/data/shp-africa/municipalities/gadm36_1.shp"
shp_world = st_read(shp_path)


esp = shp_world %>%
  filter(NAME_0 == "Spain",
         NAME_1 == "Castilla y León")
         #!NAME_1 == "Islas Canarias",)
plot(esp)


ntl_path = "/Users/rodrigo/Documents/tfg/data/DMSP-OLS-NTL/F182013.v4/F182013.v4c_web.avg_vis.tif"
ntl_world = raster(ntl_path)

# cropping or masking
ntl_esp_crop = raster::crop(ntl_world, esp)
ntl_esp_maskc = raster::mask(ntl_esp_crop, esp)
plot(ntl_esp_maskc)

# summary of spain raster
hist(ntl_esp_maskc)
raster::summary(ntl_esp_maskc)

# threshold based raster classification
threshold = 30
plot(ntl_esp_maskc >= threshold)

# percentiles(three classes) + reclassify method
max = cellStats(ntl_esp_maskc, 'max')
ntl_normalized = (ntl_esp_maskc/max)*100
min = cellStats(ntl_esp_maskc, 'min')
m = matrix(c(min, 15, 1,
              15, 85, 2,
              85, Inf, 3), ncol=3, byrow=TRUE)

ntl_percentile <- reclassify(ntl_normalized, m) 
plot(ntl_percentile)



# Steps (highlights)
# 1) compute area of the class or percentiles 
# 2) find the shape of the diff green areas ("create the cities")
# 3) computational geometry: disconexion index

# 1
ntl_city = ntl_esp_maskc
ntl_city[ntl_city < threshold] = NA
ntl_city[ntl_city >= threshold] = 1
plot(ntl_city, col = "red")

urban = raster::cellStats(area(ntl_city, na.rm = TRUE), stat = sum) # 34,577.83 km2
total = raster::cellStats(area(ntl_esp_maskc, na.rm = TRUE), stat = sum) # 496,468.9 km2
perc = urban/total*100 # 6.96%
perc

# 2
city_boundaries = raster::rasterToPolygons(ntl_city, fun=NULL, n=4, na.rm=TRUE, digits=12, dissolve=TRUE)
plot(city_boundaries)

# 3
pols = city_boundaries@polygons[[1]]@Polygons # only one layer? #SpatialPOlygonDataFrame to SpatialPolygon
# package: landscapemetrics


# Thoughts:
# There are very small cities. I should disgreard those cities for my project?
# How many cities (urban markets?) do we have? Comparison with GHSL?
# Should we agregate polygons (raster::aggregate) that are close together (1,2,4,8 km)?
# If we do it, should we do it after or before we use rasterToPolygons? I think before.




##################################################################################################################

# JOIN GHSL-UCDB with NTL data 
# Idea: I want to analyze only the cities that appear in UCSB, but compute the shape based on NTL data.


ucdb_shp_path = "/Users/rodrigo/Documents/urban-economics/trabajo-uc3m/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0.shp"
ucdb = st_read(ucdb_shp_path)


# Urban Centre Extension:
# BBX_LATMN – latitude of the low left corner of the bounding box;
# BBX_LONMN - longitude of the low left corner of the bounding box;
# BBX_LATMX - latitude of the top right corner of the bounding box;
# BBX_LONMX - longitude of the top right corner of the bounding box.


# Location:
# GCPNT_LAT: Latitude of the geometric centroid;
# GCPNT_LON: Longitude of the geometric centroid;


esp_ucdb_sh = ucdb %>%
  filter(CTR_MN_ISO == "ESP")
  #filter(!UC_NM_MN == "Santa Cruz De Tenerife [ESP]" ) %>%
  #filter(!UC_NM_MN == "Las Palmas Gran Canaria [ESP]" ) %>%
  #filter(!UC_NM_MN == "Ceuta [ESP]; Fnideq [MAR]") %>%
  #filter(!UC_NM_MN == "Vilanova I La G [ESP]")

plot(esp_ucdb_sh$geometry)
# compare this shapes to the ones I get with NTL data?
# What year are these shapes from? I guess 2015.

esp_ucdb_coord = as.data.frame(ucdb) %>%
  filter(CTR_MN_ISO == "ESP") %>%
  dplyr::select(GCPNT_LAT, GCPNT_LON)


# select only the cities that are in the ucdb for Spain. 
# the coordinates of the centroids have to be inside pols
points_ucdb = st_as_sf(esp_ucdb_coord, coords = c("GCPNT_LON","GCPNT_LAT"), crs = 4326)
plot(points_ucdb)


# first approach: convert to points and points into polygons sf
# https://gis.stackexchange.com/questions/332427/issues-converting-points-to-polygon-in-r

df_list = list()
for (i in seq(length(pols))) {
  coords = pols[[i]]@coords %>% as.data.frame()
  coords['id'] = i
  df_list[[i]] = coords
}
# outide the loop: vectorized function better (bind_rows)
coords = dplyr::bind_rows(df_list) 
coords_sf = st_as_sf(coords, coords=c("x","y"))  # It hink is crs = 4326(same as ucdb)

# it seems correct
pols_sf = coords_sf %>%
  group_by(id) %>%
  summarise(pol = st_combine(geometry)) %>%
  st_cast("POLYGON")

#for (i in seq(length(pols_sf$pol))){
#  plot(pols_sf[i, 2], main = i)  
#}


# pols_sf = coords_sf %>%
#   group_by(id) %>%
#   summarise() %>%
#   st_cast("POLYGON") %>%
#   st_convex_hull() st_convex_hull creates the convex hull of a set of points

# Let's imagine it works. For now we will use the polygons we have 
# and then we will find the intersection and so on because its making me crazy
# There are two ways of doing it I THINK: st_join / st_intersects.
#onlypols = st_sf(pols_sf$pol)
#st_crs(onlypols) = 4326
#st_crs(points_ucdb) = 4326
#
#intersection = st_intersects(points_ucdb$geometry, onlypols$pols_sf.pol)
#intersection = st_intersection(onlypols, points_ucdb)
#st_intersection()
#
#
#x = onlypols$pols_sf.pol[1]
#x1 = onlypols
#y = points_ucdb$geometry[1]






#####################################################################################
## COMPUTATIONAL GEOMETRY ##



