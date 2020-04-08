
# AGGREGATE POLYGONS CLOSE TO EACHOTHER BUT NOT TOUCHING ##

library(spdep)
library(rgdal)
library(sf)

#polys <- readOGR(system.file("etc/shapes/", package="spdep"), "eire")

#spobecjct_spain = as(spain_polys, 'Spatial')
#buffer = gBuffer(sp_projected, width = 2000)

# we need the ids of the polygon that intersects
#https://community.rstudio.com/t/help-me-speed-up-distances-from-polygons-to-other-polgons-in-sf/25627

within_zone = st_intersection(buffer_sf_projected, all_polys) #135 intersections?
plot(within_zone$geometry)

## WORKS
load("/Users/rodrigo/Documents/tfg/cities/data/up.RData")
spain_polys = sf::st_read('/Users/rodrigo/Documents/tfg/cities/data/created/shp/output/spain_metrics/spain_big.shp')
all_polys = sf::st_read('/Users/rodrigo/Documents/tfg/cities/data/created/shp/output/spain_metrics/spain_ShapeMetrics1.shp')

utmStr <- "+proj=utm +zone=%d +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"
crs <- CRS(sprintf(utmStr, 32))

spain_polys_planar = sf::st_transform(spain_polys, crs)
all_polys_planar = st_transform(all_polys, crs)
same_polys_id = st_equals(spain_polys_planar, all_polys_planar)

remove_vector = integer(length(same_polys_id$geometry))

for (i in seq(length(remove_vector))) {
  remove_vector[i] = same_polys_id[[i]]
}  

small_polys_planar = all_polys_planar[- remove_vector ,]
small_polys_planar$FID_1 = seq(1:587)
st_write(st_transform(small_polys_planar, CRS("+init=epsg:4326")), 
         dsn = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/input/small_spain.shp', delete_dsn = TRUE)
  
# steps:
# 1) create buffer 
# 2) ids of polygons that intersec with buffer 
# 3) join the polygons who intersect with buffer


# 1) create buffer
buffer_sf_planar = sf::st_buffer(spain_polys_planar, dist = 2000)

# 2) ids of polygons that intersec with buffer 
id_intersect = sf::st_intersects(buffer_sf_planar, small_polys_planar)

# 3) join polygons?
#https://gis.stackexchange.com/questions/193746/merging-two-adjacent-polygons-which-borders-are-not-touching-each-other


## COMMENTS ##

# urban_polygons@polygons -- LIST
# urban_polygons@polygons[[2]] -- POLYGONS
# urban_polygons@polygons[[2]]@Polygons -- LIST
# urban_polygons@polygons[[2]]@Polygons[[i]] -- POLYGON
# gbuffer does not work with either POLYGONS OR POLYGON. IT NEEDS A PROJECTION.




