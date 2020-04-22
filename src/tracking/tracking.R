library(sf)
library(raster)
library(dplyr)


## INTERSECTION BTW POINTS AND POLYGONS ##
# Goal: have a shapefile with polygons with a name
# Simpler approach compared to stampr

#checks: 
# - if point is close to a polygon I need to allow it i guess (islands and costal cities)
PolygonPointsInfo = function(IntersectionIDs, CityPoints){
  lnames = list()
  MissingPolygons = c()
  
  for (i in 1:nrow(IntersectionIDs)) {
    IDs = IntersectionIDs[[i]]
    VectorNames = c()
    for (id in IDs) {
      names = CityPoints[id, c('Name1', 'Admnm1')] %>% st_drop_geometry()
      rownames(names) = NULL
      CityName = as.character(names[1, 'Name1'])
      RegionName = as.character(names[1, 'Admin1'])
      VectorNames = c(VectorNames, CityName)
    }
    key = paste0('polygon_', as.character(i))
    if(length(IDs) > 0){
      lnames[[key]] = VectorNames
    } else{
      lnames[[key]] = '0'
      MissingPolygons = c(MissingPolygons, i)
    }
 }

  print(paste('Missing Polygons:', length(MissingPolygons)))
  return(lnames)
}
 

cities = st_read('/Users/rodrigo/Documents/tfg/cities/data/raw/citieShp/grump-v1-settlement-points-rev01-shp/global_settlement_points_v1.01.shp')
spain_points = cities[cities$Country == 'Spain' ,]
spain_points = st_transform(spain_points, 25830)
pol_files = list.files(path = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/spain',
                       pattern = ".shp", recursive = TRUE, full.names = TRUE)

lyears = list()
for (file in pol_files) {
  
  up = st_read(file) %>% 
    filter(area > 50e+06) %>% 
    sf::st_transform(25830)
  
  Intersection = st_intersects(up, spain_points)
  info = PolygonPointsInfo(IntersectionIDs = Intersection,
                           CityPoints = spain_points)
  year = stringr::str_sub(file, start = -8, end = -5)
  lyears[[year]] = info
}




######################
# UCDB #
######################

PolygonPointsInfoUCDB = function(IntersectionIDs, CityPoints, maxpop){
  lnames = list()
  MissingPolygons = c()
  
  for (i in 1:nrow(IntersectionIDs)) {
    IDs = IntersectionIDs[[i]]
    VectorNames = c()
    
    for (id in IDs) {
      names = CityPoints[id, c('UC_NM_MN', 'P00')] %>% st_drop_geometry()
      rownames(names) = NULL
      CityName = as.character(names[1, 'UC_NM_MN'])
      VectorNames = c(VectorNames, CityName) #append cityname to vector
      
      max = 0
      maxid = id
      if (names$P00 > max){
        max = names$P00
        maxid = id
      }
    }
    
    if(maxpop == TRUE & length(IDs) > 0){
      CityName = CityPoints[maxid, 'UC_NM_MN'] %>% st_drop_geometry()
      VectorNames = as.character(names[1, 'UC_NM_MN'])
    }
    
    key = paste0('polygon_', as.character(i))
    if(length(IDs) > 0){
      lnames[[key]] = VectorNames
    } else{
      lnames[[key]] = '0'
      MissingPolygons = c(MissingPolygons, i)
    }
  }
  return(lnames)
}

path_ucdb = '/Users/rodrigo/Documents/tfg/cities/data/raw/ucdb/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0.shp'
ucdb = st_read(path_ucdb)

spain_ucdb = ucdb %>%
  filter(CTR_MN_NM == 'Spain') %>%
  select(GCPNT_LON, GCPNT_LAT, UC_NM_MN, P90, P00, P15) %>%
  st_drop_geometry() %>%
  st_as_sf(coords = c("GCPNT_LON", "GCPNT_LAT"), crs = 4326) %>%
  st_transform(25830)


# plot(spain_ucdb)
# st_write(spain_ucdb, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/ucdb_points.shp', update  = T)

pol_files = list.files(path = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/spain',
                       pattern = ".shp", recursive = TRUE, full.names = TRUE)
lyearsUCDB = list()
for (file in pol_files) {
  
  up = st_read(file) %>% 
    #filter(area > 50e+06) %>% 
    sf::st_transform(25830)
  
  up_buffer = st_buffer(up, dist = 2000)
  Intersection = st_intersects(up_buffer, spain_ucdb)
  info = PolygonPointsInfoUCDB(IntersectionIDs = Intersection,
                                CityPoints = spain_ucdb, maxpop = TRUE)
  
  year = stringr::str_sub(file, start = -8, end = -5)
  lyearsUCDB[[year]] = info
}


## check if names coincide in time
# common cities across all years (40 in Spain)
# https://stackoverflow.com/questions/3695677/how-to-find-common-elements-from-multiple-vectors

common = Reduce(intersect, list(as.character(lyearsUCDB[[1]]), as.character(lyearsUCDB[[2]]),
                       as.character(lyearsUCDB[[3]]), as.character(lyearsUCDB[[4]]),
                       as.character(lyearsUCDB[[5]]), as.character(lyearsUCDB[[6]]),
                       as.character(lyearsUCDB[[7]]), as.character(lyearsUCDB[[8]]),
                       as.character(lyearsUCDB[[7]]), as.character(lyearsUCDB[[8]])))



# match names with up polygons
indexes = match(common,as.character(lyearsUCDB[[1]]))

# do this for each year and then create time series with the up polygons dastaset

# create shape of 'mis datos' PANEL DATA SET UP











  