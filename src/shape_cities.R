
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

# right format and  write shapefile
#st_up = st_as_sf(urban_polygons) 
#st_up_geometry_cities = st_up[2,]$geometry
#st_up_polygons = st_cast(st_up_geometry_cities, 'POLYGON')
#st_write(st_up_polygons, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/spain.shp')


## CREATE GENERAL FUNCTION ##


shape_cities = function(shapefile, raster, output_path, threshold_dn)
{
  # reading raster and shapefile
  shapefile = sf::st_read(shapefile)
  raster = raster::raster(raster)
  
  # get the right shape
  crop = raster::crop(raster, shapefile)  # crop: rectangle
  mask = raster::mask(crop, shapefile)    # mask: shapefile shape
  
  # threshold classification
  quantiles = raster::quantile(mask, probs = c(0.90, 0.925, 0.95, 0.975, 0.99))
  threshold = threshold_dn
  
  raster_binary = mask
  raster_binary[raster_binary < threshold] = 0
  raster_binary[raster_binary >= threshold] = 1
  
  # polygon extraction
  urban_polygons = raster::rasterToPolygons(raster_binary, fun = NULL, n = 4,
                                            na.rm = TRUE, digits = 12, dissolve = TRUE)
  # right format (sf)
  sf_urban_polygons = st_as_sf(urban_polygons) 
  sf_urban_polygons_geometry_cities = sf_urban_polygons[2,]$geometry
  sf_urban_polygons2 = st_cast(sf_urban_polygons_geometry_cities, 'POLYGON')
  
  # write output shapefile
  st_write(sf_urban_polygons2, dsn = output_path)
}
  
















