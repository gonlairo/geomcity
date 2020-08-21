setwd('/Users/rodrigo/Documents/tfg')
library(raster)
library(sf)
library(dplyr)
library(stringr)

# take care:
# 1992: some countries they dont have ups in that year; in lower and upper they are NOT removed

################################# SUMMARY ####################################
# Based on the centroids of the polygons of the first year (1992) I track the 
# polygons that contain the centroid in the rest of the years (1993-2012).
#############################################################################

##################################################################
##################################################################

# FIRST STEP #
# I read the files 1992-2012 for each country and on the
# centroid of the first year identify same polygon in all years.

# HELPER FUNCTION
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

# dirs = countries
path_dirs = 'data/ups/asia_africa/one_way/optimal_threshold'
dirs = list.dirs(path_dirs, recursive = FALSE)

countries = vector('list')
for(i in 1:length(dirs)) {
  
  # get the country and read the files for each year
  dir = dirs[i]
  ups_files = list.files(path = dir, pattern = ".shp", full.names = TRUE)
  
  # recover the country name
  dir_split = str_split(dir, "/")[[1]]
  country_name = dir_split[length(dir_split)]
  print(country_name)
 
  # read file year
  up_first = st_read(ups_files[1], quiet = TRUE) %>% st_transform(3395) 
  df_ids = data.frame(matrix(1:nrow(up_first), nrow = nrow(up_first), ncol = length(ups_files)))

  # compute centroid that lies inside polys first year
  pnts_first = st_centroid_within_poly(up_first)
  
  # loop from the second year to the last
  for (j in 2:length(ups_files)) {
    
    # read file and transform to EPSG:3395
    up = st_read(ups_files[j], quiet = TRUE) %>% st_transform(3395)
    
    # intersection with year x
    intersection = st_intersects(pnts_first, up)
   
    # change integer(0) for NA
    idx <- !(sapply(intersection, length))
    intersection[idx] = NA
   
    # append to a df_ids
    df_ids[, j] = unlist(intersection)
  }
  # append to countries list
  countries[[country_name]] = df_ids
}

##################################################################
##################################################################

# SECOND STEP #
# I read the files again and figure out which ones we can track down ("persistent")
# and create a dataframe with the polygons, the right id, year, country and lights

# IDs where there is no NA in intersection -> each year the centroid lies in a polygon
persistent_upsIDs = lapply(countries, function(df) which(rowSums(is.na(df)) == 0))

# intialize empty data structures
df_pols = NULL
id_start = 1
finaldf = vector('list')

# read files of each country
for(i in 1:length(dirs)){
  
  # get the country and read the files for each year
  dir = dirs[i]
  ups_files = list.files(path = dir, pattern = ".shp", full.names = TRUE)
  
  # recover country name
  dir_split = str_split(dir, "/")[[1]]
  country_name = dir_split[length(dir_split)]
  print(country_name)
  
  
  df_id_country = countries[[country_name]]
  persistentIDs = persistent_upsIDs[[country_name]]
  df_id_final = df_id_country[persistentIDs,]
  
  # check if there are not persistent ups
  if(!length(persistentIDs)) next
  
  # right id for df_pols and df_pols_country
  id_end = id_start + length(persistentIDs) - 1
  df_pols_country = NULL
  
  # loop over all years
  for (j in 1:length(ups_files)) {
    
    # read file and remove the "sf" flavor
    up = st_read(ups_files[j], quiet = TRUE)
    pols = up[df_id_final[, j],] %>% as.data.frame()
    
    # year, id, country
    year = stringr::str_sub(ups_files[j], start = -8, end = -5)
    pols$country = country_name
    pols$year = year
    pols$id = id_start:id_end
    
    # rbind to create the ultimate df's 
    df_pols_country = rbind(df_pols_country, pols)
    df_pols = rbind(df_pols, pols)
  }
  
  # keep df of each country in finaldf
  finaldf[[country_name]] = df_pols_country
  id_start = id_end + 1
}


##################################################################
##################################################################

# THIRD STEP: COMPUTE POPULATION #

path_ghsl_pop = 'data/data-raw/GHSL/population/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0.tif'
rpop = raster(path_ghsl_pop)

npols = nrow(df_pols)

df_pols = df_pols %>% st_as_sf()
for (i in 1:npols){
  pop_clip1 = raster::crop(rpop, df_pols[i,])
  pop_clip2 = raster::mask(pop_clip1, df_pols[i,])
  pop = raster::cellStats(pop_clip2, sum)
  df_pols$pop[i] = pop
  if(i %% 100 == 0) print(i)
}

##################################################################
##################################################################

# FOURTH STEP #
# Add continent and subregion, order it by id and write.

shp = st_read('data/shp/shp_AA_final.shp') %>%
  select(id, cntry_x, subregn, contnnt) %>%
  rename(id_c = id,
         continent = contnnt) %>%
  st_drop_geometry()

df_final = inner_join(df_pols, shp, by = c("country" = "cntry_x")) %>%
  arrange(df_pols$id) %>%
  st_as_sf()

# change projection and compute area
df_final_3395 = df_final %>%
  st_transform(3395) %>%
  mutate(area_R = st_area(df_final))

st_write(df_final, dsn = 'data/ups/ups_oneway/ups_4326.gpkg', append=FALSE)
st_write(df_final_3395, dsn = 'data/ups/ups_oneway/ups_3395.gpkg', append=FALSE)


######################################################
##################  FILTER ###########################
######################################################

ups_3395 = st_read('data/ups/ups_oneway/ups_3395.gpkg') %>%
  #mutate(area_R = area_R *1e-06) %>%
  filter(!year %in% c("2011", "2012"))

# list with separate df for each id
listdf_ids = split(ups_3395 , f = ups_3395$id)

# REMOVE POLYGONS WITH SMALL AREAS AND STRANGE GROWTH
filterpols = function(df, area, lgrowth, ugrowth){
  g = (dplyr::lead(df$area_R) - df$area_R)/df$area_R * 100
  g = g[!is.na(g)]
  
  # FILTER CONDITIONS # (sum(g < -5) > 0)
  if(sum(df$area_R < area) > 0 | sum(g > ugrowth) > 0) return(FALSE)
  return(TRUE)
}

filter_bools = lapply(listdf_ids, filterpols, area = 1e6, ugrowth = 80)
list_df_filtered = listdf_ids[unlist(filter_bools)]

# join back and remove .id
ups_3395_filtered = plyr::ldply(list_df_filtered, data.frame)
ups_3395_filtered$.id = NULL

# wirte to GPKG
st_write(ups_3395_filtered, dsn = 'data/ups/ups_oneway/ups_3395F.gpkg', append=FALSE)






