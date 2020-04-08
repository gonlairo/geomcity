optimal_threshold = function(shapefile, rlights, urban_layer, urban_threshold = 22, 
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
    rlights = urban_layer
  }
  
  
  ncountries = nrow(shapefile)
  ls_dfacc = vector("list", ncountries)
  
  for(i in 1:ncountries){
    
    country_shp = shapefile[i ,]
    
    # NTL
    lights_crop = raster::crop(rlights, country_shp)
    lights_mask = raster::mask(lights_crop, country_shp)
    
    plot(lights_mask)
    #print(country_shp$NAME_0)
    
    # urban layer
    urban_layer_crop = raster::crop(urban_layer, country_shp)
    urban_layer_mask = raster::mask(urban_layer_crop, country_shp)
    urban_layer_binary = raster::calc(urban_layer_mask, fun = function(x) {ifelse(x >= urban_threshold, 1 , 0)})
    
    df = NULL
    for (j in seq(0, delta, step)) {
      threshold = initial_threshold + j
      print(threshold)
      acc = accuracy(lights_mask, urban_layer_binary, threshold)
      df = rbind(df, acc)
    }
    colnames(df) = c('NTL-DN', 'urban_acc', 'nonurban_acc', 'average_acc')
    ls_dfacc[[i]] = df
    print('--------------------')
  }
  
  # make it more general
  #max_accuracy = function(df){
  #  max(as.numeric(df[, 'average_acc']))
  #  optimal_threshold = df[which.max(df[,4]),1]
  #  return(as.numeric(optimal_threshold))
  #}
  print(df)
  optimal_thresholds = lapply(ls_dfacc, function(df) {as.numeric(df[which.max(df[, 'average_acc']), 1])})
  return(optimal_thresholds)
}


















