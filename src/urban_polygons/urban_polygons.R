urban_polygons = function(rlights, shapefile, light_threshold,
                          output_directory, file_name)
{
  
  # urban_polygons computes the polygons geometries based on a light DN threshold 
  # as well as the amount of light in each polygon
  #
  # Inputs:
  #   @rlights (.tif or RasterLayer): raster of satellite images at night 
  #   @shapefile (.shp or sf Dataframe): shapefile to mask rlights 
  #   @light_threshold (numeric): threshold that defines what a city is 
  #
  # Output (.shp): file with the polygons geometry and lights sum.
  
  require(sf)
  require(raster)
  require(dplyr)
  
  # reading shapefile
  if (!is(shapefile, "sf")){
    shapefile = sf::st_read(shapefile)  
  } else{
    shapefile = shapefile
  }
  
  # reading raster
  if (!is(rlights, "RasterLayer")){
    rlights = raster::raster(rlights)  
  } else{
    rlights = rlights
  }
  
  # get the right shape
  crop = raster::crop(rlights, shapefile)  # crop: rectangle
  mask = raster::mask(crop, shapefile)    # mask: shapefile shape
  
  # threshold classification
  rbinary = raster::calc(mask, fun = function(x) {ifelse(x > light_threshold, 1 , NA)})
  
  if (is.na(maxValue(rbinary))) {
    print('no lights')
    return()
  }
  
  # polygon extraction
  print('-- CREATING POLYGONS --')
  urban_polygons = raster::rasterToPolygons(rbinary, n = 4,
                                            na.rm = TRUE, dissolve = TRUE)
  
  # right format (sf)
  sf_urban_polygons = st_as_sf(urban_polygons) 
  sf_urban_polygons_geometry_cities = sf_urban_polygons[, length(sf_urban_polygons)] 
  sf_urban_polygons = st_cast(sf_urban_polygons_geometry_cities, 'POLYGON')
  
  
  # calculate lights
  sf_urban_polygons$sum_lights = NA
  npols = nrow(sf_urban_polygons)
  
  for (i in 1:npols){
    lights_clip1 = raster::crop(mask, sf_urban_polygons[i,])
    lights_clip2 = raster::mask(lights_clip1, sf_urban_polygons[i,])
    lights = raster::cellStats(lights_clip2, sum)
    sf_urban_polygons$sum_lights[i] = lights
  }

  # write output shapefile
  if (!dir.exists(output_directory)) dir.create(output_directory)
    
  output = paste(output_directory, file_name, sep = '/')
  print(output)
  st_write(sf_urban_polygons, dsn = output, delete_layer = TRUE)
}
