library(stringr)
library(dplyr)
library(raster)
library(sf)
source('/Users/rodrigo/Documents/tfg/cities/src/urban_polygons.R')

########################################

# things to look at:
# - PROJECTION?

########################################

# SPAIN
lights.files = list.files(path = '/Users/rodrigo/Documents/tfg/cities/data/raw/Intercalibrated_NTL_RSR',
                          pattern = ".tif", recursive = TRUE, full.names = TRUE)

output_directory = '/Users/rodrigo/Documents/tfg/cities/data/created/raster/spain/'
path_shapefile = '/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/countries/spain.shp'

start = Sys.time()
for (file in lights.files[0:10]) {
  
  # create  file_name
  year = stringr::str_sub(file, start = -8, end = -5)
  file_name = paste('spain', paste(year, '.shp', sep = ''), sep = "_")
  print(file_name)
  
  #function call
  urban_polygons(rlights = file, shapefile = path_shapefile, light_threshold = 3500, 
                 calculate_population = FALSE, output_directory = output_directory,
                 file_name = file_name)
  
}

end = Sys.time()
time = difftime(end, start)
print(time)
system("say Just finished motherfucker! Wake up!")




africashp %>% group_by(CODE)
  summarise_all()


