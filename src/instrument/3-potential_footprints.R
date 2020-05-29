#######################################################
#############  POTENTIAL FOOTPRINTS ##################
#######################################################

library(raster)
library(sf)
library(dplyr)

# radius of 1992 = 0

path_dev.land = '/Users/rodrigo/Documents/tfg/data/raster/dev.land/africa_asia_15.tif'
path_ups      = '/Users/rodrigo/Documents/tfg/data/ups/all_radius.shp'

dev.land = raster::raster(path_dev.land)
dev.land = raster::calc(dev.land, fun = function(x) {ifelse(x == 0, NA , x)})

# I thiknk I am doing it with radius2
ups = st_read(path_ups) %>%
  mutate(radius = ifelse(year == 1992, 0, radius),
         cumsum_r = ave(radius, id_x, FUN = cumsum)) %>%
  st_transform(crs = crs(dev.land))

# mimimum bounding circle of year 1992 per each id (city)
df_circles = ups %>%
  group_by(id_x) %>%
  mutate(mbcircle92 = lwgeom::st_minimum_bounding_circle(geometry[1]),
         # create concentric circles with projected radius
         ccircles = st_buffer(mbcircle92, dist = cumsum_r * 1000))
# is the radius actually in km????????????????????

#load("/Users/rodrigo/Documents/tfg/data/instrumentdata.RData") # ups + dev.land + df_circles_pf
df_circles = st_set_geometry(df_circles, df_circles$ccircles) 

# create potential footprint with the concentric circles calculated before.
ncircles = nrow(df_circles)
df_circles$p_footprint = st_sfc(lapply(1:ncircles, function(x) st_polygon()))
for (i in 1:ncircles){
  print(i)
  circle = df_circles$mbcircle92[i] %>% st_sf()
  clip1 = raster::crop(dev.land, df_circles[i, ])
  clip2 = raster::mask(clip1, df_circles[i, ])
  
  # polygonize (very fast: 300x rastertoPolygons)
  p_footprint <- stars::st_as_stars(clip2) %>% 
    st_as_sf(merge = TRUE)
  idmax = which.max(st_area(p_footprint))
  maxareapol = p_footprint$geometry[idmax]
  #plot(maxareapol)
  df_circles$p_footprint[i] = st_sfc(maxareapol)
}

df_ccircles = st_set_geometry(df_circles, df_circles$ccircles)
df_pfootprint = st_set_geometry(df_circles, df_circles$p_footprint)
st_write(df_ccircles,   dsn = '/Users/rodrigo/Documents/tfg/data/ups/ccircles.shp')
st_write(df_pfootprint, dsn =  '/Users/rodrigo/Documents/tfg/data/ups/potential_footprints.shp')