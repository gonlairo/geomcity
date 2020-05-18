PolygonPointsInfoUCDB = function(IntersectionIDs, CityPoints, maxpop){
  
  # creates a list of length number pols per year with the structure polygon:id(name)
  #
  #
  
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
    
    # maxpop condition: get the city with highest population
    if(maxpop == TRUE & length(IDs) > 0){
      CityName = CityPoints[maxid, 'UC_NM_MN'] %>% st_drop_geometry()
      VectorNames = as.character(names[1, 'UC_NM_MN'])
    }

    key =  as.character(i)
    if(length(IDs) > 0){
      lnames[[key]] = VectorNames
    } else{
      lnames[[key]] = NA
      MissingPolygons = c(MissingPolygons, i)
      }
    }
  
  return(lnames)
}


# PolygonPointsInfo = function(IntersectionIDs, CityPoints){
#   lnames = list()
#   MissingPolygons = c()
#   
#   for (i in 1:nrow(IntersectionIDs)) {
#     IDs = IntersectionIDs[[i]]
#     VectorNames = c()
#     for (id in IDs) {
#       names = CityPoints[id, c('Name1', 'Admnm1')] %>% st_drop_geometry()
#       rownames(names) = NULL
#       CityName = as.character(names[1, 'Name1'])
#       RegionName = as.character(names[1, 'Admin1'])
#       VectorNames = c(VectorNames, CityName)
#     }
#     key = paste0('polygon_', as.character(i))
#     if(length(IDs) > 0){
#       lnames[[key]] = VectorNames
#     } else{
#       lnames[[key]] = '0'
#       MissingPolygons = c(MissingPolygons, i)
#     }
#  }
# 
#   print(paste('Missing Polygons:', length(MissingPolygons)))
#   return(lnames)
# }

# 
# cities = st_read('/Users/rodrigo/Documents/tfg/cities/data/raw/citieShp/grump-v1-settlement-points-rev01-shp/global_settlement_points_v1.01.shp')
# spain_points = cities[cities$Country == 'Spain' ,]
# spain_points = st_transform(spain_points, 25830)
# pol_files = list.files(path = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/spain',
#                        pattern = ".shp", recursive = TRUE, full.names = TRUE)
# 
# lyears = list()
# for (file in pol_files) {
#   
#   up = st_read(file) %>% 
#     filter(area > 50e+06) %>% 
#     sf::st_transform(25830)
#   
#   Intersection = st_intersects(up, spain_points)
#   info = PolygonPointsInfo(IntersectionIDs = Intersection,
#                            CityPoints = spain_points)
#   year = stringr::str_sub(file, start = -8, end = -5)
#   lyears[[year]] = info
# }
# 

