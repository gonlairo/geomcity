library(sf)
library(raster)

## INTERSECTION BTW POINTS AND POLYGONS ##
# Goal: have a shapefile with polygons with a name
# Simpler approach compared to stampr

cities = st_read('/Users/rodrigo/Documents/tfg/cities/data/raw/citieShp/grump-v1-settlement-points-rev01-shp/global_settlement_points_v1.01.shp')
spain_points = cities[cities$Country == 'Spain' ,]

spain_up = st_read('/Users/rodrigo/Documents/tfg/cities/data/created/shp/spain/spain_1999.shp')
big_spain_up = spain_up[spain_up$area > 50e+06 ,]

#change projectIon
big_spain_up = sf::st_transform(big_spain_up, 25830)
spain_points = st_transform(spain_points, 25830)
big_id_intersects = st_intersects(big_spain_up, spain_points)

lnames = list()
MissingPolygons = c()
for (i in 1:nrow(big_id_intersects)) {
  IDs = big_id_intersects[[i]]
  VectorNames = c()
  for (id in IDs) {
    names = spain_points[id, c('Name1', 'Admnm1')] %>% st_drop_geometry()
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

print(MissingPolygons)
print(length(MissingPolygons))


















