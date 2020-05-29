library(raster)


# SMOD
pathsmod90 = '/Users/rodrigo/Documents/tfg/data/raw/ghsl/smod/GHS_SMOD_POP1990_GLOBE_R2019A_54009_1K_V2_0/GHS_SMOD_POP1990_GLOBE_R2019A_54009_1K_V2_0.tif'
pathsmod00 = '/Users/rodrigo/Documents/tfg/data/raw/ghsl/smod/GHS_SMOD_POP2000_GLOBE_R2019A_54009_1K_V2_0/GHS_SMOD_POP2000_GLOBE_R2019A_54009_1K_V2_0.tif'
pathsmod15 = '/Users/rodrigo/Documents/tfg/data/raw/ghsl/smod/GHS_SMOD_POP2015_GLOBE_R2019A_54009_1K_V2_0/GHS_SMOD_POP2015_GLOBE_R2019A_54009_1K_V2_0.tif'

smod_output90 = '/Users/rodrigo/Documents/tfg/data/raw/ghsl/smod/smod90_4326.tif'
smod_output00 = '/Users/rodrigo/Documents/tfg/data/raw/ghsl/smod/smod00_4326.tif'
smod_output15 = '/Users/rodrigo/Documents/tfg/data/raw/ghsl/smod/smod15_4326.tif'

# projection with compression LZW
newprojection = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
command90 = paste(paste0("gdalwarp -t_srs \'", newprojection, "\' -r near -co \'COMPRESS=LZW\' "), pathsmod90, smod_output90)
command00 = paste(paste0("gdalwarp -t_srs \'", newprojection, "\' -r near -co \'COMPRESS=LZW\' "), pathsmod00, smod_output00)
command15 = paste(paste0("gdalwarp -t_srs \'", newprojection, "\' -r near -co \'COMPRESS=LZW\' "), pathsmod15, smod_output15)

system(command90)
system(command00)
system(command15)

# resample to the same resolution as the NTL (only one time)
smod00 = raster(smod_output00)
path_ntl = '/Users/rodrigo/Documents/tfg/data/raw/Intercalibrated_NTL_RSR/F14/F142000.tif'
random_ntl = raster(path_ntl)

# smod has slightly higer resolution than ntl images
smod00_resampled = raster::resample(smod00, random_ntl, method = 'ngb')
writeRaster(smod00_resampled, filename = '/Users/rodrigo/Documents/tfg/data/raw/ghsl/smod/smod00_resampled.tif') 


ntl_file = '/Users/rodrigo/Documents/tfg/data/raster/temporal_adjusted/twoway/avg/avg2000.tif' 
ntl10 = raster(ntl_file)
globcover_resampled = raster::resample(globcover, ntl10, method = 'ngb')
writeRaster(globcover_resampled, filename = '/Users/rodrigo/Documents/tfg/data/globcover/resampled.tif') 


########################################################################################
########################################################################################
# threshold compoutation

source('/Users/rodrigo/Documents/tfg/src/optimal_threshold/optimal_threshold_smod.R')
source('/Users/rodrigo/Documents/tfg/src/optimal_threshold/accuracy.R')

#smod resampled
path_mod = '/Users/rodrigo/Documents/tfg/data/data-raw/GHSL/smod/smod00_resampled.tif' 
path_shp = '/Users/rodrigo/Documents/tfg/data/data-raw/shapefiles/continents/AsiaAfricaShp.shp'
ntl_file = '/Users/rodrigo/Documents/tfg/data/raster/temporal_adjusted/twoway/avg/avg2000.tif'


# thresholds
result = optimal_threshold_smod(uganda, ntl_file, path_mod, urban_threshold = 30,
                                initial_threshold = 100, delta = 5000, step = 200)

df = do.call("rbind", result)
rownames(df) = NULL
write.csv(df, file = '/Users/rodrigo/Documents/tfg/data/thresholds/thresholds21.csv', row.names = FALSE)

# optimal thresholds
optimal_thresholds = lapply(result, function(df) {as.numeric(df[which.max(df[, 'average_acc']), 1])})
df_optim = t(data.frame(optimal_thresholds))
colnames(df_optim) = c('optim_threshold')
write.csv(df_optim, file = '/Users/rodrigo/Documents/tfg/data/thresholds/optimal_thresholds21.csv')


########################################################################################
########################################################################################

# GLOBCOVER

source('/Users/rodrigo/Documents/tfg/src/optimal_threshold/optimal_threshold_glob.R') 
source('/Users/rodrigo/Documents/tfg/src/optimal_threshold/accuracy.R')

path_shp = '/Users/rodrigo/Documents/tfg/data/data-raw/shapefiles/continents/AsiaAfricaShp.shp'
path_globcover = '/Users/rodrigo/Documents/tfg/data/globcover/globcover_resampled.tif'
ntl_file = '/Users/rodrigo/Documents/tfg/data/raster/temporal_adjusted/twoway/avg/avg2010.tif' 


# thresholds
result = optimal_threshold_glob(path_shp, ntl_file, path_globcover, urban_threshold = 190,
                                initial_threshold = 500, delta = 3500, step = 50)

df = do.call("rbind", result)
rownames(df) = NULL
write.csv(df, file = '/Users/rodrigo/Documents/tfg/data/thresholds/thresholds_globcover_with10s.csv', row.names = FALSE)


########################################################################################
########################################################################################

# HBASE

source('/Users/rodrigo/Documents/tfg/src/optimal_threshold/optimal_threshold_habse.R') 
source('/Users/rodrigo/Documents/tfg/src/optimal_threshold/accuracy.R')

path_shp = '/Users/rodrigo/Documents/tfg/data/data-raw/shapefiles/continents/AsiaAfricaShp.shp'
path_hbase= '/Users/rodrigo/Documents/tfg/data/data-raw/hbase/hbase_percentage_geographic_1000m.tif'
ntl_file = '/Users/rodrigo/Documents/tfg/data/raster/temporal_adjusted/twoway/avg/avg2010.tif' 


# thresholds
result = optimal_threshold_hbase(path_shp, ntl_file, path_hbase, urban_threshold = 50,
                                initial_threshold = 100, delta = 4500, step = 100)

df = do.call("rbind", result)
rownames(df) = NULL
write.csv(df, file = '/Users/rodrigo/Documents/tfg/data/thresholds/thresholds_hbase.csv', row.names = FALSE)


######################################################################
######################################################################

# ACCURACY #

library(raster)
library(sf)
path_shp = '/Users/rodrigo/Documents/tfg/data/data-raw/shapefiles/continents/AsiaAfricaShp.shp'
shapefile = sf::st_read(path_shp)
path_globcover = '/Users/rodrigo/Documents/tfg/data/globcover/globcover_resampled.tif'
urban_layer = raster::raster(path_globcover)
ntl_file = '/Users/rodrigo/Documents/tfg/data/raster/temporal_adjusted/twoway/avg/avg2010.tif' 
rlights = raster::raster(ntl_file)


country_shp = shapefile[81 ,]
country_name = as.character(country_shp$cntry_x)
print(country_name)


# urban layer
urban_layer_crop = raster::crop(urban_layer, country_shp)
urban_layer_mask = raster::mask(urban_layer_crop, country_shp)        
urban_layer_binary = raster::calc(urban_layer_mask, fun = function(x) {ifelse(x == 190, 1 , 0)})

plot(urban_layer_mask, main = 'urban layer mask')
plot(urban_layer_binary, main = 'urban layer binary with threshold')

THRESHOLD = 1500
lights_crop = raster::crop(rlights, country_shp)
lights_mask = raster::mask(lights_crop, country_shp)
lights_binary = raster::calc(lights_mask, fun = function(x) {ifelse(x >= THRESHOLD, 1 , 0)})
plot(lights_binary, main = THRESHOLD)
