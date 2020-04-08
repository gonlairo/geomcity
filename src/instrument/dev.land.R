developable.land = function(path_water, path_gdem, shapefile, slope_threshold)
{
  water = raster(path_water)
  gdem = raster(path_gdem)
  
  # crop and mask water and elevation
  wcrop = raster::crop(water, shp_esp)  
  wmask = raster::mask(wcrop, shp_esp)    
  ecrop = raster::crop(gdem, shp_esp)  
  emask = raster::mask(ecrop, shp_esp)
  
  stack = raster::stack(wmask, emask)
  developable_land = raster::overlay(stack,
                                     fun = function(x, y) {ifelse((x > 0) | (y > slope_threshold), NA, 1) })
  
  return(developable_land)
}