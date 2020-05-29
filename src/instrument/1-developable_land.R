#######################################################
################# DEVELOPABLE LAND ###################
#######################################################

setwd('/Users/rodrigo/Documents/tfg/')
path_gdem =  'data/data-raw/ASTER/afica&asia/gdem_v3/res_gdem_slope_3395.tif'
path_water = 'data/data-raw/ASTER/afica&asia/water_v1/res_water_3395.tif'

water = raster(path_water) # water: 0 for land, 1 for ocean, 2 for river, and 3 for lakes,
gdem = raster(path_gdem)   # gdem: % of slope. In theory it should be 0-100 but there are some outliers(?)

slope_thresholds = c(10, 15, 20)
for (threshold in slope_thresholds) {
  
  # stack water and gdem together: same resolution, same bbox, same projection
  stack = raster::stack(water, gdem)

  # developable land (1) if water == 0 (land) and gdem < slope_threshold
  developable_land = raster::overlay(stack,
                                     fun = function(x, y) {ifelse((x == 0) & (y < threshold), 1, 0) })
  # write raster
  filename = paste0('data/raster/dev.land/africa_asia_', threshold, '.tif')
  writeRaster(developable_land, filename = filename)
}
