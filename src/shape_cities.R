library(sf)
library(dplyr)
library(tidyr)
library(raster)

shp_path = "~/Documents/tfg/shape-cities/data/raw/shapefiles/municipalities/gadm36_1.shp"
shp_world = sf::st_read(shp_path)


shp_esp = shp_world %>%
  filter(NAME_0 == "Spain",
         # NAME_1 == "Castilla y León")
         !NAME_1 == "Islas Canarias")


ntl_path = "~/Documents/tfg/shape-cities/data/raw/dmsp-ols-ntl/F182013.v4/F182013.v4c_web.avg_vis.tif"
ntl_world = raster::raster(ntl_path)

# masking: 
ntl_esp_maskc = raster::mask(ntl_esp_crop, shp_esp)
plot(ntl_esp_maskc)

# summary of spanish raster
hist(ntl_esp_maskc, col = "green", breaks = c(1,2,3,4,5,10,20,30,40,50,60,70))
raster::summary(ntl_esp_maskc)

# percentiles(three classes) + reclassify method
max = raster::cellStats(ntl_esp_maskc, 'max')
min = cellStats(ntl_esp_maskc, 'min')
m = matrix(c(min, 15, 1,
              15, 85, 2,
              85, Inf, 3),
           ncol=3, byrow=TRUE)


ntl_normalized = (ntl_esp_maskc/max)*100
ntl_percentile = reclassify(ntl_normalized, m) 
plot(ntl_percentile)


# threshold based raster classification
quantiles = raster::quantile(ntl_esp_maskc, probs = c(0.90, 0.925, 0.95, 0.975, 0.99))
threshold = 30

plot(ntl_esp_maskc >= threshold)

# 1) compute area of the class or percentiles 
# 2) find the shapes ("create the cities")

# 1
ntl_city = ntl_esp_maskc
ntl_city[ntl_city < threshold] = NA
ntl_city[ntl_city >= threshold] = 1
plot(ntl_city, col = "red")

urban = raster::cellStats(area(ntl_city, na.rm = TRUE), stat = sum) # 34,577.83 km2
total = raster::cellStats(area(ntl_esp_maskc, na.rm = TRUE), stat = sum) # 496,468.9 km2
urban_perc = urban/total*100 # 6.96%

# 2
city_boundaries = raster::rasterToPolygons(ntl_city, fun = NULL, n = 4, na.rm=TRUE, digits = 12, dissolve = TRUE) #t = 50s
pols_allinfo = city_boundaries@polygons[[1]]  # info: plotOrder, area, ID, labpt(centroid), coords
pols = pols_allinfo@Polygons                  # info: pols_allinfo - plotOrder

# Info about types of objects:
# class(city_boundaries) = "SpatialPolygonsDataFrame" (sp)
# class(pols_allinfo) = "Polygons" (sp)
# class(pols) = "list"

# plotting
plot(city_boundaries)
plot(pols[[1]]@coords) 

# shapefile with the city_boundaries
rgdal::writeOGR(city_boundaries, dsn = '.', layer = "~/Documents/tfg/city_boundaries", driver = "ESRI Shapefile")

# Thoughts:
# There are very small cities. I should disgreard those cities for my project?
# How many cities (urban markets?) do we have? Comparison with GHSL?
# Should we agregate polygons (raster::aggregate) that are close together (1,2,4,8 km)?
# If we do it, should we do it after or before we use rasterToPolygons? I think before.
# package: landscapemetrics




