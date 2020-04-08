potential_footprint = function(polygons, developable_land, output_path)
{
  
  #
  # potential_footprint computes the potential polygon constrained by
  # geography (change this)
  #
  # Arguments:
  #   @polygons (.shp): polygons or the urban 
  #   @developable_land (.tif): developable land (binary) -- at least the extent of the polygons --
  # 
  # output: .shp file with the polygons geometry and the population and 
  #         amount of light if requested.
  # 
  
  start = Sys.time()
  pols = st_read(polygons)
  dev.land = raster(developable_land)
  dev.land = raster::calc(dev.land, fun = function(x) {ifelse(x == 0, NA , x)})
  
  bounding_circles = lwgeom::st_minimum_bounding_circle(pols) %>% st_as_sf()
  ncircles = nrow(bounding_circles)
  
  # empty sf data frame: allocation of memory
  df = st_sf(id = 1:ncircles, 
             geometry = st_sfc(lapply(1:ncircles, function(x) st_polygon())),
             crs = crs(pols))
  
  attr(st_geometry(df), "bbox") = st_bbox(pols)
  
  
  for (i in 1:ncircles)
  {
    clip1 = raster::crop(dev.land, bounding_circles[i,])
    clip2 = raster::mask(clip1, bounding_circles[i,])
    p_footprint = rasterToPolygons(clip2, dissolve = TRUE) %>% st_as_sf()
    df$geometry[i] = p_footprint$geometry
    
    
    # check if it is multipolygon or what in df
    # look at the extent error
  }

  st_write(df, output_path, delete_layer = TRUE)
  end = Sys.time()
  print(difftime(end, start))
  return(df)
}