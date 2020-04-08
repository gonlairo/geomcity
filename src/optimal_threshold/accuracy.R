accuracy = function(lights.raster, urban.binary, lights.threshold){
  
  require(raster)

  lights_binary = raster::calc(lights.raster, fun = function(x) {ifelse(x >= lights.threshold, 1 , 0)})
  
  urban.rbinary = raster::resample(urban.binary, lights_binary, method = 'ngb')
  roverlay = raster::overlay(lights_binary, urban.rbinary, fun = function(x,y) { return(x + y) })
  
  freq_burban = freq(urban.rbinary)
  freq_overlay = freq(roverlay)
  
  nonurban_accuracy = freq_overlay[1,2] / freq_burban[1,2]
  urban_accuracy = freq_overlay[3,2] / freq_burban[2,2]
  average_accuracy = (urban_accuracy + nonurban_accuracy)/2
  
  return(list(lights.threshold, urban_accuracy, nonurban_accuracy, average_accuracy))
}

