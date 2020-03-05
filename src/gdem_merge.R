library(raster)
library(doParallel)  
library(foreach)

## parallelize ##
cores = parallel::detectCores() - 1
cl = parallel::makeCluster(cores)
doParallel::registerDoParallel(cl)

input_path = '/Users/rodrigo/Documents/tfg/cities/data/raw/ASTER/gdem_v3/spain'
output_slope = '/Users/rodrigo/Documents/tfg/cities/data/raw/ASTER/gdem_v3/spain/slope/'

setwd(input_path)
files = list.files(input_path, pattern = "dem.tif", full.names = TRUE)
dir.create(output_slope)

for (file in files){
  # right name
  name = strsplit(file, split='[/.]')[[1]]
  name = name[length(name) - 1]
  name = paste(output_slope, name, "slope.tif", sep = "_")
  
  # compute slope in percentage
  system(sprintf("gdaldem slope %s %s -p -of GTiff", file, name))
}

# create virtual mosaic
setwd(output_slope)
system('gdalbuildvrt gdem.vrt *.tif')

# merge rasters into 1 file
system('gdal_translate -of GTiff gdem.vrt rmerged.tif')


