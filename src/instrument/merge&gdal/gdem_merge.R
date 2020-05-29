library(raster)

input_path = '/Users/rodrigo/Documents/tfg/data/data-raw/ASTER/gdem_v3/africa-asia'
output_path = '/Users/rodrigo/Documents/tfg/data/data-raw/ASTER/gdem_v3/africa-asia/output'

setwd(input_path)

# 1 UNIZIP
system("unzip '/Users/rodrigo/Documents/tfg/data/data-raw/ASTER/gdem_v3/africa-asia/*.zip'")


dir.create(output_path)
setwd(output_path)

# create virtual mosaic
system('gdalbuildvrt gdem_all.vrt ../*dem.tif')

# merge rasters into 1 file
system("gdal_translate -of GTiff -co 'COMPRESS=LZW' gdem_all.vrt gdem_all_merged.tif")


files = list.files(input_path, pattern = "dem.tif", full.names = TRUE)
#For locations not near the equator, it would be best to reproject your grid using gdalwarp before using gdaldem


for (file in files){
  # right name
  name = strsplit(file, split='[/.]')[[1]]
  name = name[length(name) - 1]
  name = paste(output_slope, name, "slope.tif", sep = "_")
  
  # compute slope in percentage
  system(sprintf("gdaldem slope %s %s -p -of GTiff", file, name))
}



