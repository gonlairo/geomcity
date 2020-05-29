
clear
echo "enter the directory path:"

read directory

#unzip files
unzip '*.zip'

# build virtual mosaic
gdalbuildvrt gdem.vrt *dem.tif

# merge rasters into 1 file
gdal_translate -of GTiff -co 'COMPRESS=LZW' gdem.vrt gdem_merged.tif

mkdir output
mv gdem.vrt gdem_merged.tif output/
rm *.tif
