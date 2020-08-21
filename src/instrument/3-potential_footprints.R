#######################################################
#############  POTENTIAL FOOTPRINTS ##################
#######################################################
setwd('/Users/rodrigo/Documents/tfg')
library(raster)
library(sf)
library(dplyr)

path_dev.land = 'data/raster/dev.land/africa_asia_15.tif'
path_ups      = 'data/ups/ups_avg/ups_3395.gpkg'

dev.land = raster::raster(path_dev.land)
dev.land = raster::calc(dev.land, fun = function(x) {ifelse(x == 0, NA , x)})

# read polygons, remove NA and compute cumulative radius
ups = st_read(path_ups) %>%
  na.omit() %>%
  mutate(radius = ifelse(year == 1992, 0, radius),
         cumsum_r = ave(radius, id, FUN = cumsum))

# mimimum bounding circle of year 1992 per each id (city)
df_circles = ups %>%
  group_by(id) %>%
  mutate(mbcircle92 = lwgeom::st_minimum_bounding_circle(geom[1]),
         # create concentric circles with projected radius
         ccircles = st_buffer(mbcircle92, dist = cumsum_r * 1000))

# set geometry to the concentric circles
df_circles = st_set_geometry(df_circles, df_circles$ccircles) 

# create potential footprint with the concentric circles calculated before.
ncircles = nrow(df_circles)
df_circles$pf = st_sfc(lapply(1:ncircles, function(x) st_polygon()))
for (i in 32936:ncircles){
  if(i %% 250 == 0) print(i)
  circle = df_circles$mbcircle92[i] %>% st_sf()
  clip1 = raster::crop(dev.land, df_circles[i, ])
  clip2 = raster::mask(clip1, df_circles[i, ])
  #plot(clip2)
  
  
  # polygonize (very fast: 300x rastertoPolygons)
  # trycatch: https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
  p_footprint = tryCatch(
    expr = {
      stars::st_as_stars(clip2) %>% st_as_sf(merge = TRUE)
    },
    error = function(e){ 
      # Do this if an error is caught...
      print('cannot polygonize with stars')
      rasterToPolygons(clip2) %>% st_as_sf()
    }
  )
  
  if(length(p_footprint$geometry) == 0) {
    print("length = 0")
    df_circles$pf[i] = NA
    next
  }

  idmax = which.max(st_area(p_footprint))
  maxareapol = p_footprint$geometry[idmax]
  plot(maxareapol)
  df_circles$pf[i] = st_sfc(maxareapol)
}

# remove NA


df_ccircles = df_circles %>%
  st_as_sf() %>%
  st_set_geometry(df_circles$ccircles) %>%
  dplyr::select(id, year)

df_pfootprint = df_circles %>%
  st_as_sf() %>%
  st_set_geometry(df_circles$pf) %>%
  dplyr::select(id, year)

attr(st_geometry(df_pfootprint), "bbox") = st_bbox(df_ccircles)
df_pfootprint = df_pfootprint %>% st_set_crs(3395)

st_write(df_ccircles,   dsn = 'data/ups/ups_avg/ccircles_3395.gpkg', append = FALSE)
st_write(df_pfootprint, dsn =  'data/ups/ups_avg/pf_vm/potential_footprints_3395.shp', append = FALSE)


