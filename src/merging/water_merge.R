input_path = '/Users/rodrigo/Documents/tfg/cities/data/raw/ASTER/water_v1/spain'
#output = '/Users/rodrigo/Documents/tfg/cities/data/raw/ASTER/water_v1/spain/output'

setwd(input_path)
system("unzip '*.zip'")
system('mkdir output')

# create virtual mosaic
system('gdalbuildvrt output/gdem.vrt *att.tif')

# merge rasters into 1 file
system('gdal_translate -of GTiff output/gdem.vrt output/rmerged_att.tif')

# delete .tif files
system('rm *.tif')

