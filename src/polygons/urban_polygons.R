urban_polygons = function(rlights, shapefile, light_threshold, 
                          calculate_lights = TRUE,
                          calculate_population = FALSE, rpop, 
                          output_directory, file_name)
{
  
  #
  # urban_polygons computes the polygons geometries based on a light DN threshold 
  # as well as the amount of light and the population for each polygon.
  #
  # Inputs:
  #   @rlights (.tif or RasterLayer): raster of satellite images at night 
  #   @shapefile (.shp or sf Dataframe): shapefile to mask rlights 
  #   @light_threshold (numeric): threshold that defines what a city is 
  #   @calculate_lights (bool): computes the amount of light in each polygon 
  #   @calculate_population (bool): computes the amount of populaton in each polygon 
  #
  # Output (.shp): file with the polygons geometry and the population 
  #                and amount of light if requested.
  # 
  
  
  start = Sys.time()
  require(sf)
  require(raster)
  require(dplyr)
  
  # reading raster and shapefile
  
  if (!is(shapefile, "sf")){
    shapefile = sf::st_read(shapefile)  
  } else{
    shapefile = shapefile
  }
  
  if (!is(rlights, "RasterLayer")){
    rlights = raster::raster(rlights)  
  } else{
    rlights = rlights
  }
  
  
  # get the right shape
  crop = raster::crop(rlights, shapefile)  # crop: rectangle
  mask = raster::mask(crop, shapefile)    # mask: shapefile shape
  
  #if(light_threshold > 6300 | light_threshold < 0) stop("threshold out of bounds")

  # threshold classification
  rbinary = raster::calc(mask, fun = function(x) {ifelse(x > light_threshold, 1 , NA)})
  
  # polygon extraction
  print('-- CREATING POLYGONS --')
  urban_polygons = raster::rasterToPolygons(rbinary, n = 4,
                                            na.rm = TRUE, dissolve = TRUE)
  
  # right format (sf)
  sf_urban_polygons = st_as_sf(urban_polygons) 
  sf_urban_polygons_geometry_cities = sf_urban_polygons[, length(sf_urban_polygons)] 
  sf_urban_polygons = st_cast(sf_urban_polygons_geometry_cities, 'POLYGON')
  
  #sf_urban_polygons$area = round(st_area(sf_urban_polygons), 2) 
  sf_urban_polygons$prod = NA
  sf_urban_polygons$pop = NA
  
  npols = nrow(sf_urban_polygons)
  
  if(calculate_lights){
    for (i in 1:npols){
      prod_clip1 = raster::crop(mask, sf_urban_polygons[i,])
      prod_clip2 = raster::mask(prod_clip1, sf_urban_polygons[i,])
      productivity = raster::cellStats(prod_clip2, sum)
      sf_urban_polygons$prod[i] = productivity
    }
  }
  
  if(calculate_population){
    rpop = raster(rpop)
    for (i in 1:npols) {
      pop_clip1 = raster::crop(rpop, sf_urban_polygons[i,])
      pop_clip2 = raster::mask(pop_clip1, sf_urban_polygons[i,])
      pop = raster::cellStats(pop_clip2, sum)
      sf_urban_polygons$pop[i] = pop
    }
  }
  
  #remove columns that are NA
  sf_urban_polygons[, colSums(is.na(sf_urban_polygons)) != nrow(sf_urban_polygons)]
  
  # round pop and lights
  if(calculate_lights) round(sf_urban_polygons$prod, 2)
  if(calculate_population) round(sf_urban_polygons$pop, 2)
  
  # write output shapefile
  if (!dir.exists(output_directory)) dir.create(output_directory)
    
  output = paste(output_directory, file_name, sep = '')
  st_write(sf_urban_polygons, dsn = output, delete_layer = TRUE)

  end = Sys.time()
  print(difftime(end, start))
}
