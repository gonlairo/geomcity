library(sf)
library(raster)

source('/Users/rodrigo/Documents/tfg/cities/src/potential_footprint.R')
path_spain = '/Users/rodrigo/Documents/tfg/cities/data/up_spain.shp'
path_dev.land_spain = '/Users/rodrigo/Documents/tfg/cities/data/created/raster/developable_land_spain.tif'
path_output = '/Users/rodrigo/Documents/tfg/cities/data/pf.shp'


pf_spain = potential_footprint(polygons = path_spain,
                               developable_land = path_dev.land_spain,
                               output_path = path_output)
