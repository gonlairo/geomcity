
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
id_intersect = st_intersects(buffer_sf_planar, small_polys_planar)

# 3) join polygons?
#https://gis.stackexchange.com/questions/193746/merging-two-adjacent-polygons-which-borders-are-not-touching-each-other

#example

x = spain_polys_planar[2,]
x1 = buffer_sf_planar[2,]
plot(x$geometry)
plot(x1$geometry)
y = small_polys_planar[56,]
plot(y$geometry)

joint_pol = st_union(x, y)
joint_pol1 = st_union(x1, y)
plot(joint_pol$geometry)
plot(joint_pol1$geometry)


#stackoverflow

coords1 <- cbind(c(2, 4, 4, 1, 2), c(2, 3, 5, 4, 2))
spy1 <- mapview::coords2Polygons(coords1, ID = "A")
plot(spy1)
coords2 <- cbind(c(5, 4, 2, 5), c(2, 3, 2, 2))
spy2 <- mapview::coords2Polygons(coords2, ID = "B")

plot(spy1)
plot(spy2)


outer = matrix(c(0,0,10,0,10,10,0,10,0,0),ncol=2, byrow=TRUE)
hole1 = matrix(c(1,1,1,2,2,2,2,1,1,1),ncol=2, byrow=TRUE)
hole2 = matrix(c(5,5,5,6,6,6,6,5,5,5),ncol=2, byrow=TRUE)

pol1 = list(outer, hole1, hole2)
pol2 = list(outer + 12, hole1 + 12)
pol3 = list(outer + 24)


sf_pol = st_polygon(pol3)
plot(sf_pol)
mp = list(pol1,pol2,pol3)
z =st_cast(joint_pol, 'POLYGON')
plot(z$geometry)






## COMMENTS ##

# cuando conviertes a datafrmae mirar vairable Rstudio para entender la geometría y no debería haaber problemas
# el problema viene al crear el shapefile porque crea como si fuera una sola gemetría y por eso hay que pasarlo a sf POLYGONS o algo asi

# PROBLEMA BUFFER: Disminuye el numero de "buffers" (los une, 65 vs 62) si dos poligonos estan muy cerca. Hacerlo uno por uno?
# como de costoso computacionalmente? y si un poligono esta entre medias de dos grandes a cual lo uno?

# urban_polygons@polygons -- LIST
# urban_polygons@polygons[[2]] -- POLYGONS
# urban_polygons@polygons[[2]]@Polygons -- LIST
# urban_polygons@polygons[[2]]@Polygons[[i]] -- POLYGON
# gbuffer does not work with either POLYGONS OR POLYGON. IT NEEDS A PROJECTION.









