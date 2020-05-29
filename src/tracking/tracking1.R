setwd('/Users/rodrigo/Documents/tfg')
library(raster)
library(sf)
library(dplyr)
library(stringr)
source('src/tracking/PolygonPointsInfoUCDB.R')

path_urban_layer = 'data/data-raw/GHSL/ucdb/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0.shp'
ul = st_read(path_urban_layer) # CRS: 4326

ul = ul %>%
  dplyr::select(GCPNT_LON, GCPNT_LAT, UC_NM_MN, P90, P00, P15) %>%
  st_drop_geometry() %>%
  st_as_sf(coords = c("GCPNT_LON", "GCPNT_LAT"), crs = 4326) %>%
  st_transform(25830) ######## CHANGE THIS TO A WORLD PROJECTION, NOT A SPAIN UTM PROJECTION


path = 'data/ups/asia_africa'
dirs = list.dirs(path) # dirs = countries 
dirs = dirs[-1]        # remove asia_africa directory

df = NULL
id_start = 1

for (d in 1:length(dirs)) {

  dir = dirs[d]
  
  # 21 files per country
  pol_files = list.files(path = dir, pattern = ".shp", full.names = TRUE)
  
  # create lyearsUCDB (list of years with polygons associated with them and the names)
  lyearsUCDB = list()
  
  for (i in 1:length(pol_files)) {
    
    # why do i do this? # why I do change the projection?
    up = st_read(pol_files[i], quiet = TRUE) %>% 
      st_transform(25830) ######## CHANGE THIS TO A WORLD PROJECTION, NOT A SPAIN UTM PROJECTION
    
    up_buffer = st_buffer(up, dist = 3000)
    Intersection = st_intersects(up_buffer, ul)
    info = PolygonPointsInfoUCDB(IntersectionIDs = Intersection,
                                 CityPoints = ul, maxpop = TRUE)
    
    year = stringr::str_sub(pol_files[i], start = -8, end = -5)
    lyearsUCDB[[year]] = info
  }
  
  
  
  ###########################
  # Common names of citites #
  ###########################
  
  common = Reduce(intersect, lyearsUCDB)
  common = common[!is.na(common)] # remove NA as common name
  
  dir_split = str_split(dir, "/")[[1]]
  country_name = dir_split[length(dir_split)]
  print(country_name)
  
  id_end = id_start + length(common) - 1
  for (j in 1:length(pol_files)) {
     
    # no cities in common
    if(!length(common)) {
      print(country_name)
      break
    }
    
     up = st_read(pol_files[j], quiet = TRUE) 
     
     #one way
     indexes = match(common, lyearsUCDB[[j]])
     newup = up[indexes ,]
     
     # id 
     newup$id = id_start:id_end
    
     # year, country and city name
     year = stringr::str_sub(pol_files[j], start = -8, end = -5)
     newup$year    = year
     newup$country = country_name
     newup$city    = common
     
     # add to df
     df = rbind(df, newup)
  }
  
  id_start = id_end + 1
  print('--other country--')
}

df_ordered = dplyr::arrange(df)
df_ordered = df_ordered[order(df_ordered$id) , ] # %>% st_transform(4326)
df_ordered$city = unlist(df_ordered$city)
st_write(df_ordered, dsn = '/Users/rodrigo/Documents/tfg/data/ups/all_citynames.shp')
