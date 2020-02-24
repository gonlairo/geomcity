library(raster)
library(sf)

path_raster_pop = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/population/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0.tif'
pop_raster = raster::raster(path_raster_pop)

path_up_spain = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/output/spain_metrics/spain_ShapeMetrics1.shp'
up_spain = sf::st_read(path_up_spain) 

for (i in seq(1:length(up_spain$geometry))) {
  clip1 = raster::crop(pop_raster, up_spain[i,])
  clip2 = raster::mask(clip1, up_spain[i,])
  sumpop = raster::cellStats(clip2, sum)
  up_spain["pop"] = sumpop # doesnt work
                            #parallelize? https://cran.r-project.org/web/packages/doParallel/vignettes/gettingstartedParallel.pdf
}


crop = raster::crop(pop_raster, up_spain[652,])
mask = raster::mask(crop, up_spain[652,])


