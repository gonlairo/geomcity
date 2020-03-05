library(raster)
library(dplyr)

path_water = '/Users/rodrigo/Documents/tfg/cities/data/raw/ASTER/water_v1/spain/output/small_water.tif'
path_gdem = '/Users/rodrigo/Documents/tfg/cities/data/raw/ASTER/gdem_v3/spain/slope/small_slope.tif'
path_shapefile = "~/Documents/tfg/cities/data/raw/shapefiles/municipalities/gadm36_1.shp"
  
shp_world = sf::st_read(path_shapefile)
shp_esp = shp_world %>%
  filter(NAME_0 == "Spain",
         !NAME_1 == "Islas Canarias")


water = raster(path_water)
gdem = raster(path_gdem)

wcrop = raster::crop(water, shp_esp)  
wmask = raster::mask(wcrop, shp_esp)    

ecrop = raster::crop(gdem, shp_esp)  
emask = raster::mask(ecrop, shp_esp)    


stack = raster::stack(wmask, emask)
sthreshold = 5e+06
developable_land = raster::overlay(stack, fun = function(x, y) {ifelse((x > 0) | (y > slope), 0, 1) })
plot(developable_land)  


writeRaster(developable_land, '/Users/rodrigo/Documents/tfg/cities/data/created/raster/developable_land.tif')


### POLYGONS IN 1975 ###

path_builtup_1975 = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/built-up/GHS_BUILT_LDS1975_GLOBE_R2018A_54009_1K_V2_0/GHS_BUILT_LDS1975_GLOBE_R2018A_54009_1K_V2_0.tif'

builtup_1975 = raster(path_builtup_1975)
wgs84 = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
builtup_1975 = raster::projectRaster(builtup_1975, crs = wgs84, method = "ngb")

bucrop = raster::crop(builtup_1975, shp_esp)  
bumask = raster::mask(bucrop, shp_esp)    


# delineate polygon




# minimum enclosing circle
x = multipoint
lwgeom::st_minimum_bounding_circle(x)
#https://www.rdocumentation.org/packages/lwgeom/versions/0.1-7


#centroid of the polygon



