
clear
echo "enter the directory path:"

read directory

#unzip files
unzip '*.zip'

# build virtual mosaic
gdalbuildvrt gdem.vrt *dem.tif

# merge rasters into 1 file
gdal_translate -of GTiff gdem.vrt rmerged.tif

mkdir output
mv gdem.vrt rmerged.tif output/
rm *.tif
