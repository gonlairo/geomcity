
###################################  
# TRACKING POLYGONS THROUGHT TIME #
###################################


# first approach: population + centroid
# I dont think it will work
up.files = list.files(path = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/spain',
                      pattern = '.shp', full.names = TRUE)

first = st_read(up.files[1]) %>% st_transform(crs = "+proj=moll")
centroids_first = st_centroid(first$geometry)

ids = c()
for (file in up.files[2]) {
  pols = st_read(file) %>% st_transform(crs = "+proj=moll")
  intersection = st_intersects(pols, centroids_first)
  for(i in 1:length(intersection)){
    if(length(intersection[[i]]) > 0){
      ids = append(ids, i)
    }
  }
  
  keep = pols[ids ,]
  # THEY ARE NOT THE SAME: 35 VS 40 WHAT IS GOING ON?
}

mp = st_combine(first$geometry[1:3])
circle = lwgeom::st_minimum_bounding_circle(mp)

z = x[x$area > 100e+6 ,]
y = x[x$area > 15e+6 ,]
plot(z$geometry)
plot(y$geometry)
x



# second approach: multipolygons and area

up.files = list.files(path = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/spain',
                      pattern = '.shp', full.names = TRUE)

up_1992 = as(st_read(up.files[1]), "Spatial") 
up_1992 = spTransform(up_1992, CRS("+init=epsg:2062"))
up_1999 = as(st_read(up.files[8]), "Spatial")
up_1999 = spTransform(up_1999, CRS("+init=epsg:2062"))

up_1992$ID = 1:nrow(up_1992)
up_1999$ID = (max(up_1992$ID) + 1):(max(up_1992$ID) + nrow(up_1999))

track = stamp(up_1992, up_1999, dc = 1, direction = FALSE, distance = FALSE, shape = FALSE)


up_1992_small = up_1992[up_1992$area > 100e+6 ,]
up_1992_small$ID = 1:nrow(up_1992_small)
up_1999$ID = (max(up_1992_small$ID) + 1):(max(up_1992_small$ID) + nrow(up_1999))

track_small = stamp(up_1992_small, up_1999, dc = 5000, direction = FALSE, distance = FALSE, shape = FALSE)

library("stampr")
data("fire1", package = "stampr")
data("fire2", package = "stampr")

# get stable polygons

stable = track[track$LEV1 == 'STBL' ,]
stable_small = track_small[track_small$LEV1 == 'STBL' ,]


id1 = stable_small$ID1
id2 = stable_small$ID2




### UCDB ##

path_ucdb = '/Users/rodrigo/Documents/tfg/cities/data/raw/ucdb/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0.shp'
ucdb = st_read(path_ucdb)
spain_ucdb = ucdb[ucdb$CTR_MN_NM == 'Spain' ,]

x =spain_ucdb %>% 
  st_geometry(st_point(c(GCPNT_LON, GCPNT_LAT)))








