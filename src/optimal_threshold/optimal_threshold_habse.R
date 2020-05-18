optimal_threshold_hbase = function(shapefile, rlights, urban_layer, urban_threshold = 22, 
                                  initial_threshold, delta, step){
  
  require(sf)
  require(raster)
  
  # reading raster and shapefile
  if (!is(shapefile, "sf") && !is(shapefile, "data.frame") ){
    shapefile = sf::st_read(shapefile)  
  } else{
    shapefile = shapefile
  }
  
  if (!is(rlights, "RasterLayer")){
    rlights = raster::raster(rlights)  
  } else{
    rlights = rlights
  }
  
  if (!is(urban_layer, "RasterLayer")){
    urban_layer = raster::raster(urban_layer)  
  } else{
    urban_layer = urban_layer
  }
  
  ncountries = nrow(shapefile)
  ls_dfacc = list() 
  
  for(i in 1:ncountries){
    
    country_shp = shapefile[i ,]
    country_name = as.character(country_shp$cntry_x)
    
    # NTL
    lights_crop = raster::crop(rlights, country_shp)
    lights_mask = raster::mask(lights_crop, country_shp)
    
    #plot(lights_mask, main = country_shp$country.x)
    
    
    # urban layer
    urban_layer_crop = raster::crop(urban_layer, country_shp)
    urban_layer_mask = raster::mask(urban_layer_crop, country_shp)        # change to >= depending on the layer
    urban_layer_binary = raster::calc(urban_layer_mask, fun = function(x) {ifelse(x >= urban_threshold, 1 , 0)})
    
    #plot(urban_layer_mask, main = 'urban layer mask')
    #plot(urban_layer_binary, main = 'urban layer binary with threshold')
    
    #print(freq(urban_layer_binary))
    
    df = data.frame()
    for (j in seq(0, delta, step)) {
      threshold = initial_threshold + j
      print(threshold)
      acc = accuracy(lights_mask, urban_layer_binary, threshold)
      df = rbind(df, acc)
    }
    
    colnames(df) = c('DN', 'urban_acc', 'nonurban_acc', 'average_acc')
    rownames(df) = NULL
    df$id = country_name
    
    print(country_name)
    print(df)
    
    ls_dfacc[[country_name]] = df
    print('--------------------')
    
  }

  return(ls_dfacc)
}



