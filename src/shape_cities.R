
library(dplyr)
library(tidyr)
library(sf)     # vector data
library(raster) # raster data


# read shapefile
shp_path = "~/Documents/tfg/cities/data/raw/shapefiles/municipalities/gadm36_1.shp"
shp_world = sf::st_read(shp_path)

shp_esp = shp_world %>%
  filter(NAME_0 == "Spain",
         NAME_1 == "Castilla y León",
         !NAME_1 == "Islas Canarias")

# read raster
ntl_path = "/Users/rodrigo/Documents/tfg/cities/data/raw/Intercalibrated_NTL_RSR/F10/F101992.tif"
ntl_world = raster::raster(ntl_path)

# merge raster and shapefile
ntl_esp_crop = raster::crop(ntl_world, shp_esp)     # crop: rectangle
ntl_esp_maskc = raster::mask(ntl_esp_crop, shp_esp) # mask: shapefile shape

## RASTER CLASSIFICATION ##

# PERCENTILES #
# 0: no light
# 1:1th-15th perc
# 2:15th-85th perc
# 3:85th-100th perc
max = raster::cellStats(ntl_esp_maskc, 'max')
min = raster::cellStats(ntl_esp_maskc, 'min')
m = matrix(c(1 , 15,  1,
             15, 85,  2,
             85, 100, 3),
           ncol=3, byrow=TRUE)

ntl_normalized = (ntl_esp_maskc/max)*100
ntl_percentile = reclassify(ntl_normalized, m) 
#plot(ntl_percentile)

# THRESHOLD #
quantiles = raster::quantile(ntl_esp_maskc, probs = c(0.90, 0.925, 0.95, 0.975, 0.99))
threshold = 30*100

ntl_city = ntl_esp_maskc
ntl_city[ntl_city < threshold] = 0
ntl_city[ntl_city >= threshold] = 1
#plot(ntl_city)


## RASTER TO POLYGON CONVERSION ##

urban_polygons = raster::rasterToPolygons(ntl_city, fun = NULL, n = 4, na.rm = TRUE, digits = 12, dissolve = FALSE) #t = 50s for Spain


# dissolve: logical. If TRUE, polygons with the same attribute value will be dissolved into multi-polygon regions.
# If dissolve = FALSE I get A LOT of polygons. If dissolve = TRUE, it makes more sense.
# look into
# https://github.com/rspatial/raster/blob/master/R/rasterToPolygons.R
# https://www.rdocumentation.org/packages/sp/versions/1.3-2/topics/aggregate
# change function of a package:
# trace(raster::rasterToPolygons, edit = TRUE)

pols_allinfo = urban_polygons@polygons[[1]]  # info: plotOrder, area, ID, labpt(centroid), coords
pols = pols_allinfo@Polygons                  # info: pols_allinfo - plotOrder

# Info about types of objects:
# class(urban_boundaries) = "SpatialPolygonsDataFrame" (sp)
# class(pols_allinfo) = "Polygons" (sp)
# class(pols) = "list"

# plotting
#plot(city_boundaries)
#plot(pols[[1]]@coords) 

# write shapefile of urban_polygons
setwd("/Users/rodrigo/Documents/tfg/shape-cities/data/created")
rgdal::writeOGR(urban_polygons, dsn = '.', layer = "urban_polygons", driver = "ESRI Shapefile")


# Thoughts:
# There are very small cities. I should disgreard those cities for my project?
# How many cities (urban markets?) do we have? Comparison with GHSL?
# Should we agregate polygons (raster::aggregate) that are close together (1,2,4,8 km)?
# If we do it, should we do it after or before we use rasterToPolygons? I think before.
# package: landscapemetrics

# Summary statistics

# summary of spanish raster
hist(ntl_esp_maskc, col = "green", breaks = c(1,2,3,4,5,10,20,30,40,50,60,70))
raster::summary(ntl_esp_maskc)

# summary of the threshold raster
urban = raster::cellStats(area(ntl_city, na.rm = TRUE), stat = sum) # 34,577.83 km2
total = raster::cellStats(area(ntl_esp_maskc, na.rm = TRUE), stat = sum) # 496,468.9 km2
urban_perc = urban/total*100 # 6.96%


