library(raster)

# ntl files ordered by year
ntl.files = list.files('tfg/data/raster/comp+others', 
                       pattern = '.tif', full.names = TRUE, recursive = TRUE)

##################################################
# ONE WAY TEMPORTAL ADJUSTMENT Liu: et al (2012) #
##################################################

OneWayItertemporalFun = function(r0, r, r1) {ifelse(r1 == 0, 0, ifelse((r1 > 0) & (r0 > r1), r0, r))}

for (i in 12:(length(ntl.files) - 1)) {
  r0 = raster(ntl.files[[i - 1]])
  r = raster(ntl.files[[i]])
  r1 = raster(ntl.files[[i + 1]])
  
  print(ntl.files[[i-1]])
  print(ntl.files[[i]])
  print(ntl.files[[i+1]])
  year = stringr::str_sub(ntl.files[[i]], start = -8, end = -5)
  print(year)
  r_ta = overlay(r0, r, r1, fun = OneWayItertemporalFun)
  
  output = paste0('/Users/rodrigo/Documents/tfg/data/raster/temporal_adjusted/oneway/', year, '.tif')
  print(output)
  writeRaster(r_ta, filename = output, overwrite = TRUE)
}
  
#################################################
# TWO WAY TEMPORAL ADJUSTMENT: Liu et al (2015) #
#################################################

ForwardItertemporalFun = function(r, r0) {ifelse(r0 > r, r0, r)}

for (i in 2:length(ntl.files)) {
  r0 = raster(ntl.files[[i - 1]])
  r = raster(ntl.files[[i]])
 
  print(ntl.files[[i-1]])
  print(ntl.files[[i]])
 
  year = stringr::str_sub(ntl.files[[i]], start = -8, end = -5)
  print(year)
  r_fta = overlay(r, r0, fun = ForwardItertemporalFun)
  
  output = paste0('data/raster/temporal_adjusted/twoway/forward/', year, '.tif')
  writeRaster(r_fta, filename = output, overwrite = TRUE)
}

BackwardItertemporalFun = function(r, r1) {ifelse(r1 < r, r1, r)}

for (i in (length(ntl.files) - 1):1) {
  r = raster(ntl.files[[i]])
  r1 = raster(ntl.files[[i + 1]])
  
  print(ntl.files[[i]])
  print(ntl.files[[i+1]])
  year = stringr::str_sub(ntl.files[[i]], start = -8, end = -5)
  print(year)
  
  r_bta = overlay(r, r1, fun = BackwardItertemporalFun)
  output = paste0('data/raster/temporal_adjusted/twoway/backward/', year, '.tif')
  writeRaster(r_bta, filename = output, overwrite = TRUE)
}

# Average forward and backward
forward.files = list.files('data/raster/temporal_adjusted/twoway/forward',
                           pattern = '.tif', full.names = TRUE)

backward.files = list.files('tfg/data/raster/temporal_adjusted/twoway/backward',
                           pattern = '.tif', full.names = TRUE)



# copy by hand from backward/b1992.tif
output92 = 'data/raster/temporal_adjusted/twoway/avg/avg1992.tif'

for (i in 13:(length(forward.files) - 1)) {
  
  ff = forward.files[[i]]
  bf = backward.files[[i+1]]
  
  # average them
  print(ff)
  print(bf)
  year = stringr::str_sub(ff, start = -8, end = -5)
  output = paste0('tfg/data/raster/temporal_adjusted/twoway/avg/avg', year, '.tif')
  avg = overlay(raster(ff), raster(bf), fun = function(x, y) {(x + y)/2})
  writeRaster(avg, file = output)
  print('----')
}

# copy by hand from forward/f2012.tif
output12 = 'tfg/data/raster/temporal_adjusted/twoway/avg/avg2012.tif'

########################
# TESTING AND ACCURACY #
########################

## diference between raster and t -1 and t + 1

diffbefore = overlay(r0, x, fun = function(x, y) {ifelse(x == y, 0, 1)})
diffafter = overlay(r1, x, fun = function(x, y) {ifelse(x == y, 0, 1)})

pctchangebef = cellStats(diffbefore, sum)/ncell(diffbefore) # 3% = 23*10ˆ6
pctchangeaft = cellStats(diffafter, sum)/ncell(diffafter)  # 4%


# testing overlay average
x = matrix(c(1,2,3,4),2,2)
y = matrix(c(2,3,4,5),2,2)

r = overlay(raster(x),raster(y), fun = function(x, y) {(x + y)/2})
as.matrix(r)