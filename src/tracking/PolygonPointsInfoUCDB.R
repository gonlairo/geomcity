PolygonPointsInfoUCDB = function(IntersectionIDs, CityPoints, maxpop){
  # creates a list of length number pols per year with the structure polygon:id(name)
  
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




