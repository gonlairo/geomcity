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















