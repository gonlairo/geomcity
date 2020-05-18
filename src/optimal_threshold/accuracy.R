accuracy = function(lights.raster, urban.binary, lights.threshold){
  
  require(raster)

  lights_binary = raster::calc(lights.raster, fun = function(x) {ifelse(x >= lights.threshold, 1 , 0)})
  
  #urban.binary = raster::resample(urban.binary, lights_binary, method = 'ngb')
  roverlay = raster::overlay(lights_binary, urban.binary, fun = function(x , y) {ifelse(x == y, (x+y), ifelse(x == 1 & y == 0, 10, 20))})
  
  # 0: correcly classified non urban
  # 2: correcly classified urban
  # 10: error -> urban in lights, nonurban in urban layer
  # 20: error -> non urban in lights, urban in urban layer
  
  plot(lights_binary, main = paste('lights', lights.threshold))
  freq_blights = as.data.frame(freq(lights_binary))
  freq_burban =  as.data.frame(freq(urban.binary))
  freq_overlay = as.data.frame(freq(roverlay))
  
  freq_blights = freq_blights[- nrow(freq_overlay) , ]
  freq_burban =  freq_burban[- nrow(freq_burban)   , ]
  freq_overlay = freq_overlay[- nrow(freq_overlay) , ]
  
  # print("freq overlay(lights+urban)")
  # print(freq_overlay)
  # print("freq lights binary")
  # print(freq_blights)
  # print("freq urban binary")
  # print(freq_burban)
  # 
  nup   = freq_burban[freq_burban$value == 1, 'count'] # number of urban pixels in urban layer
  nnup  = freq_burban[freq_burban$value == 0, 'count'] # number of non urban pixels in urban layer
  
  upcc       = freq_overlay[freq_overlay$value ==  2, 'count']  # urban pixels correcly classified
  nupcc      = freq_overlay[freq_overlay$value ==  0, 'count']  # nonurban pixels correcly classified
  number_10s = freq_overlay[freq_overlay$value == 10, 'count']
  number_20s = freq_overlay[freq_overlay$value == 20, 'count']
  
  if(!length(nup)) nup = NA
  if(!length(nnup)) nnup = NA
  if (!length(upcc)) upcc = NA
  if (!length(nupcc)) nupcc = NA
  if (!length(number_10s)) number_10s = NA
  if (!length(number_20s)) number_20s = NA

  urban_accuracy    = upcc / nup
  nonurban_accuracy = nupcc / nnup
  average_accuracy  = (urban_accuracy + nonurban_accuracy)/2
  
  print('--- another threshold ----')
  return(list(lights.threshold, nup, nnup, upcc, nupcc, number_10s, number_20s, urban_accuracy, nonurban_accuracy, average_accuracy))
}












