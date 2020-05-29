setwd('/Users/rodrigo/Documents/tfg')
library(raster)
library(sf)
library(dplyr)
library(stringr)
#PROJECTION:
# I cant calculate the are in 4326. I need a projected CRS.

path_dirs = 'data/ups/asia_africa/optimal_threshold'
dirs = list.dirs(path_dirs, recursive = FALSE) # dirs = countries 

diff = c()
countries = c()

for (i in 1:length(dirs)) {
 dir = dirs[i]
 ups_files = list.files(path = dir, pattern = ".shp", full.names = TRUE)
 
 dir_split = str_split(dir, "/")[[1]]
 country_name = dir_split[length(dir_split)]
 print(country_name)
 
 # read file year 1992 and keep polys with area > 1kmˆ2
 up92 = st_read(ups_files[1], quiet = TRUE)
 up92_final = up92 %>%
   mutate(area92 = as.numeric(st_area(up92)) * 1e-06) %>%
   filter(area92 > 5)
 
 first = nrow(up92_final)
 print(first)
 
 # compute centroid inside polys of year 1992
 # pnts92 = st_centroid_within_poly(up_final)
 if(!length(ups_files)) print('hey')
 for (j in length(ups_files)) {
   
   up = st_read(ups_files[j], quiet = TRUE)
   
   up_final = up %>%
     mutate(area = as.numeric(st_area(up)) * 1e-06) %>%
     filter(area > 5)
   #intersection = st_intersects(up, pnts92)
   end = nrow(up_final)
   print(end)
 }
 
 
 countries = c(countries, country_name)
 diff = c(diff, (end - first))
}


# HELPER FUNCTIONS
st_centroid_within_poly <- function (poly) {
  
  # check if centroid is in polygon
  centroid <- poly %>% st_centroid() 
  in_poly <- st_within(centroid, poly, sparse = F)[[1]] 
  
  # if it is, return that centroid
  if (in_poly) return(centroid) 
  
  # if not, calculate a point on the surface and return that
  centroid_in_poly <- st_point_on_surface(poly) 
  return(centroid_in_poly)
}
