library(stringr)
library(dplyr)
library(raster)
library(sf)

path_mod = '/Users/rodrigo/Documents/tfg/cities/data/raw/ghsl/mod/mod_4326.tif'
path_lights = '/Users/rodrigo/Documents/tfg/cities/data/raw/Intercalibrated_NTL_RSR/F14/F142000.tif'
path_shapefile = '/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/countries/spain.shp'

shapefile = sf::st_read(path_shapefile)

# GHSL-MOD
mod = raster(path_mod)
# crop and mask mod
mod_crop = raster::crop(mod, shapefile)
mod_mask = raster::mask(mod_crop, shapefile)
# urban classification
urban_threshold = 22
mod_binary = raster::calc(mod_mask, fun = function(x) {ifelse(x >= urban_threshold, 1 , 0)})

# LIGHTS
rlights = raster(path_lights)
# crop and mask lights
lights_crop = raster::crop(rlights, shapefile)
lights_mask = raster::mask(lights_crop, shapefile)

# binarize the true one and resample (idk the order)
mod_binary = raster::calc(mod_mask, fun = function(x) {ifelse(x >= urban_threshold, 1 , 0)})
mod_rbinary = raster::resample(mod_binary, lights_binary, method = 'ngb')

initial_threshold = 2000
df = NULL
for (i in seq(0, 3000, 500)) {
  threshold = initial_threshold + i
  print(threshold)
  acc = accuracy(lights_mask, mod_rbinary, threshold)
  df = rbind(df, acc)
}
colnames(df) = c('NTL-DN', 'urban_acc', 'nonurban_acc', 'average_acc')
print(df)
max_accuracy = max(as.numeric(df[, 'average_acc']))
optimal_threshold = df[which.max(df[,4]),1]

accuracy = function(lights.raster, urban.binary, lights.threshold){
  
  lights_binary = raster::calc(lights.raster, fun = function(x) {ifelse(x >= lights.threshold, 1 , 0)})
  roverlay = overlay(lights_binary, urban.binary, fun = function(x,y) { return(x + y) })
  
  freq_bmod = freq(mod_binary_resampled)
  freq_overlay = freq(roverlay)
  
  nonurban_accuracy = freq_overlay[1,2] / freq_bmod[1,2]
  urban_accuracy = freq_overlay[3,2] / freq_bmod[2,2]
  average_accuracy = (urban_accuracy + nonurban_accuracy)/2
  
  return(list(lights.threshold, urban_accuracy, nonurban_accuracy, average_accuracy))
}










