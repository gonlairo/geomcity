library(raster)
library(dplyr)
library(sp)
library(sf)




## EXAMPLE CIRCLES SPAIN ##

# minimum enclosing circle: it works with polygons from sp

pols = st_read('/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/spain_buffer.shp')
pols = st_transform(pols, crs = 4326)
circles = lwgeom::st_minimum_bounding_circle(pols)

# developable land inside polygon
path_developable_land = '/Users/rodrigo/Documents/tfg/cities/data/created/raster/developable_land_spain.tif'
developable_land = raster(path_developable_land)
developable_land_NA =  raster::calc(developable_land, fun = function(x) {ifelse(x == 0, NA , x)}) # do it always, this way we dont have 2 layers afer polygonize

ncircles = length(circles$geometry)
df = st_sf(id = 1:ncircles, 
           geometry = st_sfc(lapply(1:ncircles, function(x) st_multipolygon())),
           crs = st_crs(pols))
start = Sys.time()
for (i  in 1:10){
  print(i)
  clip1 = raster::crop(developable_land_NA, circles[i,])
  print(i)
  clip2 = raster::mask(clip1, circles[i,])
  print(i)
  potential_footprint = rasterToPolygons(clip2, dissolve = TRUE) %>% st_as_sf()
  print(i)
  df$geometry[i] = potential_footprint$geometry
  print(i)
}

end = Sys.time()
print(difftime(start, end)) #3 MIN 10 CIRCLES

1 - ## WE NEED TO THINK ABOUT THE EXTENT OF CIRCLES COMPARED TO THE SHAPEFILE FOR CROPPING AND MASKING ##

2 - ## MULTIPOLYGONS  TO POLYGONS TO CALCULATE SHAPE METRICSS##
# get outer polygon of the polygons
pols = st_cast(st_potential_footprint, 'POLYGON')
x = st_read('/Users/rodrigo/Documents/ArcGIS/potential_footprint_mp_Shape2.shp')
x[2,]$geometry == pols[1,]$geometry # TRUE
































### POLYGONS IN 1975 ###

# population
path_pop_1975 = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/population/GHS_POP_E1975_GLOBE_R2019A_4326_9ss_V1_0/GHS_POP_E1975_GLOBE_R2019A_4326_9ss_V1_0.tif'
pop_1975 = raster(path_pop_1975)

popcrop = raster::crop(pop_1975, shp_esp)  
popmask = raster::mask(popcrop, shp_esp)  

quantiles = raster::quantile(popmask, probs = c(0.90, 0.925, 0.95, 0.975, 0.99))
threshold = 300
bpopmask = raster::calc(popmask, fun = function(x) {ifelse(x > threshold, 1 , NA)})
plot(bpopmask)

up_pop = raster::rasterToPolygons(bpopmask, fun = NULL, n = 4, na.rm = TRUE, digits = 12, dissolve = TRUE)
st_up_builtup = st_as_sf(up_pop) 
st_up_builtup_geometry = st_up_builtup[1,]$geometry
st_up_builtup_polygons = st_cast(st_up_builtup_geometry, 'POLYGON')
st_write(st_up_builtup_polygons, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/spain_pop_1975_300.shp')

##########
 
# BUILT UP #
path_builtup_1975 = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/built-up/GHS_BUILT_LDS1975_GLOBE_R2018A_54009_1K_V2_0/GHS_BUILT_LDS1975_GLOBE_R2018A_54009_1K_V2_0.tif'

builtup_1975 = raster(path_builtup_1975)
shp_esp_mollweide = sf::st_transform(shp_esp, crs = "+proj=moll")

#wgs84 = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
#builtup_1975 = raster::projectRaster(builtup_1975, crs = wgs84, method = "ngb")

bucrop = raster::crop(builtup_1975, shp_esp_mollweide)  
bumask = raster::mask(bucrop, shp_esp_mollweide)    

quantiles = raster::quantile(bumask, probs = c(0.90, 0.925, 0.95, 0.975, 0.99))
threshold = 8
bumask_binary = raster::calc(bumask, fun = function(x) {ifelse(x > threshold, 1 , NA)})
plot(bumask_binary)
up_builtup = raster::rasterToPolygons(bumask_binary, fun = NULL, n = 4, na.rm = TRUE, digits = 12, dissolve = TRUE)

st_up_builtup = st_as_sf(up_builtup) 
st_up_builtup_geometry = st_up_builtup[2,]$geometry
st_up_builtup_polygons = st_cast(st_up_builtup_geometry, 'POLYGON')

#st_write(st_up_builtup_polygons, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/spain_builtup_1975.shp')






## EXAMPLE SPAIN DEVELOPABLE LAND ##

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
developable_land = raster::overlay(stack, fun = function(x, y) {ifelse((x > 0) | (y > sthreshold), NA, 1) })
plot(developable_land)  
#writeRaster(developable_land, '/Users/rodrigo/Documents/tfg/cities/data/created/raster/developable_land.tif')


