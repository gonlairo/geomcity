source('/Users/rodrigo/Documents/tfg/cities/src/optimal_threshold/optimal_threshold.R')
source('/Users/rodrigo/Documents/tfg/cities/src/optimal_threshold/accuracy.R')

path_mod = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/mod/mod_4326.tif' #change to ngb
path_ntl = '/Users/rodrigo/Documents/tfg/cities/data/raw/Intercalibrated_NTL_RSR/F14/F142000.tif'
path_shp = '/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/countries/Spain.shp'

threshold = optimal_threshold(path_shp, path_ntl, path_mod, urban_threshold = 22, 
                              initial_threshold = 1500, delta = 3500, step = 500)
