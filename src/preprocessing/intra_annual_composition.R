library(raster)

ntl.files = list.files('data/raw/Intercalibrated_NTL_RSR', 
                       pattern = '.tif', full.names = TRUE, recursive = TRUE)

# get the right files and put them into a list
years = 1992:2012
intra_annual_files = vector("list")

for (t in years) {
  vectorfiles = c()
  for (file in ntl.files){
    year = stringr::str_sub(file, start = -8, end = -5)
    if (t == year) {
      vectorfiles = c(vectorfiles, file)
    }
    if (length(vectorfiles) > 1) {
      intra_annual_files[[as.character(t)]] = vectorfiles
    }
  }
}

# function as described in Liu et al (2012)
compositefun = function(x,y) { ifelse((x ==0 | y == 0), 0, (x + y)/2) }

# equivalent fucnction
# compositefun = function(x,y) { ifelse((x > 0 & y == 0) | (x == 0 & y > 0), 0, (x + y)/2) }

for (i in intra_annual_files) {
  r0 = raster(i[1])
  r1 = raster(i[2])
  print(i[1])
  print(i[2])
  
  year = stringr::str_sub(i[1], start = -8, end = -5)
  output = paste0('tfg/data/created/raster/annual_composites/c', year, '.tif')
  composite = overlay(r0, r1, fun = compositefun)
  writeRaster(composite, filename = output, overwrite = TRUE)
}

# toy example to understand the function behavior
#r0 = raster(matrix(c(1,5,6,0),2,2))
#r1 = raster(matrix(c(0,1,1,1),2,2))
#composite = overlay(r0, r1, fun = compositefun)