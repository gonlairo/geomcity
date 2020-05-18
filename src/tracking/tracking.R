library(sf)
library(raster)
library(dplyr)
library(ggplot2)

## INTERSECTION BTW POINTS AND POLYGONS ##
# Goal: have a shapefile with polygons with a name
# Simpler approach compared to stampr

#checks: 
# - if point is close to a polygon I need to allow it i guess (islands and costal cities)
# plot(spain_ucdb)
# st_write(spain_ucdb, dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/ucdb_points.shp', update  = T)

######################
     # UCDB #
######################

path_ucdb = '/Users/rodrigo/Documents/tfg/data/raw/ucdb/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0.shp'
ucdb = st_read(path_ucdb)

spain_ucdb = ucdb %>%
  filter(CTR_MN_NM == 'Spain') %>%
  select(GCPNT_LON, GCPNT_LAT, UC_NM_MN, P90, P00, P15) %>%
  st_drop_geometry() %>%
  st_as_sf(coords = c("GCPNT_LON", "GCPNT_LAT"), crs = 4326) %>%
  st_transform(25830)

# create lyearsUCDB (list of years with polygons associated with them and the names)
source('PolygonPointsInfoUCDB.R')

pol_files = list.files(path = '/Users/rodrigo/Documents/tfg/data/created/shp/spain',
                       pattern = ".shp", recursive = TRUE, full.names = TRUE)
lyearsUCDB = list()
for (file in pol_files) {
  
  up = st_read(file) %>% 
    filter(area > 50e+06) %>% 
    sf::st_transform(25830)
  
  up_buffer = st_buffer(up, dist = 2000)
  Intersection = st_intersects(up_buffer, spain_ucdb)
  info = PolygonPointsInfoUCDB(IntersectionIDs = Intersection,
                                CityPoints = spain_ucdb, maxpop = TRUE)
  
  year = stringr::str_sub(file, start = -8, end = -5)
  lyearsUCDB[[year]] = info
}


#############################################################################
#############################################################################

# common cities across all years (40 in Spain)
# https://stackoverflow.com/questions/3695677/how-to-find-common-elements-from-multiple-vectors
common = Reduce(intersect, lyearsUCDB)
common[[1]] = NULL # remove NA as common name

df = NULL
for (i in 1:length(pol_files)) {
  file = pol_files[i]
  
  up = st_read(file) %>% 
    filter(area > 50e+06)
  
  indexes = match(common, lyearsUCDB[[i]])
  
   #one way
   newup = up[indexes ,]
   newup$id = 1:length(common)
   
   year = stringr::str_sub(file, start = -8, end = -5)
   newup$year = year
   
   #st_write(newup, paste0('/Users/rodrigo/Documents/tfg/data/created/shp/', year, 'fspain.shp'))
   df = rbind(df, newup)
}

df$pop = NULL
df$area = df$area/1e+06


#############################################################################
#############################################################################

# problems with polygons that change area more than 30% in a year
df_idyear =df %>% st_drop_geometry() %>% 
  group_by(id, year) %>% 
  summarise_all(sum)

for (i in seq(0, 320, 8)) {
  x = df_idyear[i:(i + 8), ]
  print(x)
  break
}


ggplot(df, aes(x = year, y = area, group = id, color = id)) +
  geom_line() + 
  xlab("")

# individual
x = df[df$id == 1, c('area', 'year')]
ts.plot(x$area)



# I NEED TO CONSIDER MULTIPOLYGONS AND JOIN THEM TOGETHER OR SOMETHING.
















