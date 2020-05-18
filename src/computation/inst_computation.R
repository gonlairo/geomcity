library(raster)
library(sf)
library(dplyr)

source('/Users/rodrigo/Documents/tfg/src/instrument/potential_footprint.R')

# COMPUTE DEVELOPABLE LAND

path_gdem = '/Users/rodrigo/Documents/tfg/data/data-raw/ASTER/gdem_v3/africa-asia/output/slope_gdem_mercator.tif'
path_water = '/Users/rodrigo/Documents/tfg/data/data-raw/ASTER/water_v1/africa-asia/output/output_water_mercator.tif'

water = raster(path_water)
gdem = raster(path_gdem)

slope_threshold = 20
stack = raster::stack(water, gdem)
developable_land = raster::overlay(stack,
                                   fun = function(x, y) {ifelse((x > 0) | (y > slope_threshold), 0, 1) })
writeRaster(developable_land, filename = '/Users/rodrigo/Documents/tfg/data/raster/dev.land/africa_asia_20.tif')

# POTENTIAL FOOTPRINT (once we have a binary raster of developable land)


### CHANGE PROJECTION TO METERS TO CALCUALATE BUFFERS!!!!!!!!!
path_dev.land = 
path_ups = '/Users/rodrigo/Documents/tfg/data/ups/all_radius.shp'


#ups2012 = ups %>% filter(year == 2012)
ups = st_read(path_ups) %>%
      mutate(cumsum_r = ave(radius, id_x, FUN = cumsum)) %>%
      st_transform(crs = 3785)

df_circles_pf = lwgeom::st_minimum_bounding_circle(ups) %>% st_as_sf()
ncircles = nrow(df_circles_pf)

COL_RADIUS = 10
for (j in 1:(ncircles - 1)) {
  if (j %% 21 == 0) next
  print(j)
  radius = df_circles_pf[j, COL_RADIUS] %>% st_drop_geometry() %>% as.numeric()
  print(radius)
  df_circles_pf$geometry[j + 1] = st_buffer(df_circles_pf$geometry[j], dist = radius * 1000) # dist in km->m(*1000)
}
  

# empty sf data frame: allocation of memory
df = st_sf(id = 1:ncircles,
          geometry = st_sfc(lapply(1:ncircles, function(x) st_polygon())),
          crs = crs(ups))

#attr(st_geometry(df), "bbox") = st_bbox(pols)

dev.land = raster(path_dev.land)
dev.land = raster::calc(dev.land, fun = function(x) {ifelse(x == 0, NA , x)})

for (i in 1:ncircles)
{
  clip1 = raster::crop(dev.land, df_circles_pf[i,])
  clip2 = raster::mask(clip1, df_circles_pf[i,])
  
  p_footprint = rasterToPolygons(clip2, dissolve = TRUE) %>% st_as_sf()
  df_circles_pf$p_footprint[i] = p_footprint$geometry
}


# get the biggest patch of contiguous developable land inside each circle.