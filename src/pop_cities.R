library(raster)
library(sf)

path_raster_pop_1990 = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/population/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0.tif'
path_raster_built_1990 = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/built-up/GHS_BUILT_LDS1990_GLOBE_R2018A_54009_1K_V2_0/GHS_BUILT_LDS1990_GLOBE_R2018A_54009_1K_V2_0.tif'
pop_raster = raster::raster(path_raster_pop_1990)
built_raster = raster::raster(path_raster_built_1990)

built_raster_latlon = raster::projectRaster(built_raster, CRS("+init=epsg:4326"))


#projection(built_raster) = projection(pop_raster)
#projection(pop_raster) == projection(built_raster)

path_up_spain = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/spain.shp'
up_spain = sf::st_read(path_up_spain) 
npols = length(up_spain$geometry)
up_spain["pop"] = 0

for (i in seq(npols)){
  clip1 = raster::crop(pop_raster, up_spain[i,])
  clip2 = raster::mask(clip1, up_spain[i,])
  sumpop = raster::cellStats(clip2, sum)
  up_spain$pop[i] = sumpop 
}

up_big = up_spain[up_spain$pop > 50000 ,]
st_write(up_big, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/output/spain_big.shp')

#parallelize? https://cran.r-project.org/web/packages/doParallel/vignettes/gettingstartedParallel.pdf
