library(stringr)
library(dplyr)
library(raster)
library(sf)

source('/Users/rodrigo/Documents/tfg/cities/src/urban_polygons.R')
path_shapefile = '/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/continents/Africa.shp'
AfricaShp = st_read(path_shapefile)

# same name different satellites?
ntl.files = list.files(path = '/Users/rodrigo/Documents/tfg/cities/data/raw/Intercalibrated_NTL_RSR',
                       pattern = ".tif", recursive = TRUE, full.names = TRUE)
start = Sys.time()
for (i in 1:nrow(AfricaShp)) {
  country_shp = AfricaShp[i ,]
  NAME = country_shp$GID_0
  THRESHOLD = 100 # country_shp$optimal_threshold
  
  output_directory = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/africa/'
  
  # parallelize this loop?
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

end = Sys.time()
time = difftime(end, start)
print(time)
system("say Done!")


################################################################################################

### PARALELLZATION ## 
# it seems to work

library(doParallel)  #Foreach Parallel Adaptor 
library(foreach)     #Provides foreach looping construct

#Define how many cores you want to use
UseCores = detectCores() - 1

#Register CoreCluster
cl = makeCluster(UseCores)
registerDoParallel(cl)

# SAME BUT WITH INNER LOOP PARALLEL
for (i in 1:nrow(AfricaShp)) {
  country_shp = AfricaShp[i ,]
  NAME = country_shp$GID_0
  THRESHOLD = 100 # country_shp$optimal_threshold
  
  output_directory = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/africa/'
  
  # parallelize this loop?
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








