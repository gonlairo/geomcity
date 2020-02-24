
library(dplyr)
library(tidyr)
library(sf)     # vector data
library(raster) # raster data


# read shapefile
shp_path = "~/Documents/tfg/cities/data/raw/shapefiles/municipalities/gadm36_1.shp"
shp_world = sf::st_read(shp_path)

shp_esp = shp_world %>%
  filter(NAME_0 == "Spain",
         !NAME_1 == "Islas Canarias")

# read raster
ntl_path = "/Users/rodrigo/Documents/tfg/cities/data/raw/Intercalibrated_NTL_RSR/F10/F101992.tif"
ntl_world = raster::raster(ntl_path)

# merge raster and shapefile
ntl_esp_crop = raster::crop(ntl_world, shp_esp)     # crop: rectangle
ntl_esp_maskc = raster::mask(ntl_esp_crop, shp_esp) # mask: shapefile shape

## RASTER CLASSIFICATION ##

# PERCENTILES #
max = raster::cellStats(ntl_esp_maskc, 'max')
min = raster::cellStats(ntl_esp_maskc, 'min')
m = matrix(c(1 , 15,  1,       # 0: no light
             15, 85,  2,       # 1:1th-15th perc
             85, 100, 3),      # 2:15th-85th perc
           ncol=3, byrow=TRUE) # 3:85th-100th perc

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

urban_polygons = raster::rasterToPolygons(ntl_city, fun = NULL, n = 4, na.rm = TRUE, digits = 12, dissolve = TRUE)
st_up = st_as_sf(urban_polygons)
st_up_geometry_cities = st_up[2,]$geometry
st_up_polygons = st_cast(st_up_geometry_cities, 'POLYGON')
st_write(st_up_polygons, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/spain.shp')


#pols_allinfo = urban_polygons@polygons[[1]]  # info: plotOrder, area, ID, labpt(centroid), coords
#pols = pols_allinfo@Polygons                  # info: pols_allinfo - plotOrder

# plotting
#plot(urban_polygons)
#plot(pols[[2]]@coords)



# look into
# https://github.com/rspatial/raster/blob/master/R/rasterToPolygons.R
# https://www.rdocumentation.org/packages/sp/versions/1.3-2/topics/aggregate

# change function of a package:
# trace(raster::rasterToPolygons, edit = TRUE)

# pols_allinfo = urban_polygons@polygons[[1]]  # info: plotOrder, area, ID, labpt(centroid), coords
# pols = pols_allinfo@Polygons                  # info: pols_allinfo - plotOrder
# how to get the 100 polygon
# urban_polygons@polygons[[100]]@Polygons[[1]])

# Info about types of objects:
# class(urban_boundaries) = "SpatialPolygonsDataFrame" (sp)
# class(pols_allinfo) = "Polygons" (sp)
# class(pols) = "list"


# aggregate with maptools: https://cran.r-project.org/web/packages/maptools/maptools.pdf
# https://rdrr.io/cran/maptools/man/unionSpatialPolygons.html
# map overlay
# https://cran.r-project.org/web/packages/sp/vignettes/over.pdf

## WRITE RASTER##
#setwd("/Users/rodrigo/Documents/tfg/cities/data/created")
#rgdal::writeOGR(urban_polygons, dsn = '.', layer = "try", driver = "ESRI Shapefile")


# Thoughts:
# There are very small cities. I should disgreard those cities for my project?
# How many cities (urban markets?) do we have? Comparison with GHSL?
# Should we agregate polygons (raster::aggregate) that are close together (1,2,4,8 km)?
# If we do it, should we do it after or before we use rasterToPolygons?


#https://stackoverflow.com/questions/12196440/extract-feature-coordinates-from-spatialpolygons-and-other-sp-classes?noredirect=1&lq=1
#converted = ggplot2::fortify(urban_polygons)























