library(stringr)
library(dplyr)
library(raster)
library(sf)

source('/Users/rodrigo/Documents/tfg/src/polygons/urban_polygons.R')
path_shapefile = '/Users/rodrigo/Documents/tfg/data/ups/finalshp.shp'

shapefile = st_read(path_shapefile)[67:81 , ]
ntl.files = list.files(path = '/Users/rodrigo/Documents/tfg/data/raster/final',
                       pattern = ".tif", full.names = TRUE)



for (i in 1:nrow(shapefile)) {
  country_shp = shapefile[i ,]
  NAME = as.character(country_shp$cntry_x)
  THRESHOLD = country_shp$optm_th
  
  print(NAME)
  print(THRESHOLD)
  
  # change the output direcory to have one folder per country
  output_directory = paste0('/Users/rodrigo/Documents/tfg/data/ups/asia_africa/', NAME)
  
  for (ntl.raster in ntl.files) {

    # create  file_name
    year = stringr::str_sub(ntl.raster, start = -8, end = -5)
    file_name = paste(NAME, paste0(year, '.shp'), sep = "_")
    print(file_name)

    #function call
    urban_polygons(rlights = ntl.raster, shapefile = country_shp, light_threshold = THRESHOLD,
                  calculate_population = FALSE, output_directory = output_directory,
                  file_name = file_name)
  }
}


#####################
## PARALELLZATION ## 
#################### 

library(doParallel)  #Foreach Parallel Adaptor 
library(foreach)     #Provides foreach looping construct

#Define how many cores you want to use
UseCores = detectCores() - 1

#Register CoreCluster
cl = makeCluster(UseCores)
registerDoParallel(cl)


for (i in 1:nrow(shapefile)) {
  country_shp = shapefile[i ,]
  NAME = country_shp$cntry_x
  THRESHOLD = 100 #country_shp$optim_threshold
  
  
  output_directory = '/Users/rodrigo/Documents/tfg/data/created/shp/asia_africa/,msdfgn'
  
  foreach(i=1:length(ntl.files)) %dopar% {
    
    library(raster)
    library(stringr)
    
    ntl.raster = ntl.files[i]
    
    
    # create  file_name
    year = stringr::str_sub(ntl.raster, start = -8, end = -5)
    file_name = paste(NAME, paste0(year, '.shp'), sep = "_")
    print(file_name)
    
    #function call
    urban_polygons(rlights = ntl.raster, shapefile = country_shp, light_threshold = THRESHOLD, 
                   calculate_population = FALSE, output_directory = output_directory,
                   file_name = file_name)
  }
}

stopCluster(cl)