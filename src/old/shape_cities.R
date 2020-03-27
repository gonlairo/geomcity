library(dplyr)
library(tidyr)
library(sf)     
library(raster) 


path_africa = '/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/africa_codes.csv'
africa = read.csv(path_africa)
africa_ids = as.character(africa$id)

# read shapefile
shp_path = "~/Documents/tfg/cities/data/raw/shapefiles/municipalities/gadm36_1.shp"
shp_world = sf::st_read(shp_path) 

shp_africa = shp_world %>%
  filter(GID_0 %in% africa_ids)

shp_esp = shp_world %>%
  filter(NAME_0 == "Spain",
         !NAME_1 == "Islas Canarias")

# read raster
ntl_path = "/Users/rodrigo/Documents/tfg/cities/data/raw/Intercalibrated_NTL_RSR/F10/F101992.tif"
ntl_world = raster::raster(ntl_path)

# merge raster and shapefile

start_time <- Sys.time()
ntl_esp_crop = raster::crop(ntl_world, shp_africa)     # crop: rectangle
ntl_esp_maskc = raster::mask(ntl_esp_crop, shp_africa) # mask: shapefile shape
end_time <- Sys.time()
print(difftime(end_time, start_time))

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
threshold = 25*100
ntl_city = raster::calc(ntl_esp_maskc, fun = function(x) {ifelse(x < threshold, NA , 1)})


## RASTER TO POLYGON CONVERSION ##
start_time <- Sys.time()
urban_polygons = raster::rasterToPolygons(ntl_city, fun = NULL, n = 4, na.rm = TRUE, digits = 12, dissolve = TRUE)
end_time <- Sys.time()
print(difftime(end_time, start_time))
# right format and  write shapefile
st_up = st_as_sf(urban_polygons) 
st_up_geometry_cities = st_up[, length(st_up)]
st_up_polygons = st_cast(st_up_geometry_cities, 'POLYGON')
st_write(st_up_polygons, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/africa.shp')


## CREATE GENERAL FUNCTION ##


shape_cities = function(shapefile, rlights, threshold, 
                        cross_pop_light, rpop, pop_threshold, 
                        calculate_productivity,
                        calculate_area,
                        output_path)
{
  # reading raster and shapefile
  shapefile = sf::st_read(shapefile)
  rlights = raster::raster(rlights)
  
  # get the right shape
  crop = raster::crop(rlights, shapefile)  # crop: rectangle
  mask = raster::mask(crop, shapefile)    # mask: shapefile shape
  
  # threshold classification
  rbinary = raster::calc(mask, fun = function(x) {ifelse(x > threshold, 1 , NA)})
  
  # polygon extraction
  urban_polygons = raster::rasterToPolygons(rbinary, n = 4,
                                            na.rm = TRUE, dissolve = TRUE)
  # right format (sf)
  sf_urban_polygons = st_as_sf(urban_polygons) 
  sf_urban_polygons_geometry_cities = sf_urban_polygons[, length(sf_urban_polygons)] #geometry
  sf_urban_polygons = st_cast(sf_urban_polygons_geometry_cities, 'POLYGON')
  
  sf_urban_polygons$area = st_area(sf_urban_polygons)
  sf_urban_polygons$productivity = NA
  npols = nrow(sf_urban_polygons)
  for (i in 1:npols){
    if(calculate_productivity){
      prod_clip1 = raster::crop(rlights, sf_urban_polygons[i,])
      prod_clip2 = raster::mask(pclip1, sf_urban_polygons[i,])
      productivity = raster::cellStats(prod_clip2, sum)
      sf_urban_polygons$productivity[i] = productivity
    }
    
      
    #if(cross_pop_light){
    #  rpop = raster::raster(rpop)
    #  pop_clip1 = raster::crop(rpop, sf_urban_polygons[i,])
    #  pop_clip2 = raster::mask(pop_clip1, sf_urban_polygons[i,])
    #  sumpop = raster::cellStats(pop_clip2, sum)
    #    
    #  # create 
    #  up_spain$pop[i] = sumpop
    #  up_big = up_spain[up_spain$pop > 50000 ,]  
    #}
  }

  
  # write output shapefile
  st_write(sf_urban_polygons, dsn = output_path)
  
  
}
    
    
  
  
  
















