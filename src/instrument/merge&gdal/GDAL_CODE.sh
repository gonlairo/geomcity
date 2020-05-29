# downsample gdem
gdal_translate -co COMPRESS=LZW -outsize 20% 20% -r average gdem_all_merged.tif gdem_all_merged_resample.tif

# downsample water
gdal_translate -co COMPRESS=LZW -outsize 20% 20% -r nearest water_all_merged.tif gdem_all_merged_resample.tif

# clip a raster with shapefile
gdalwarp -of GTiff -co COMPRESS=LZW -cutline /Users/rodrigo/Documents/tfg/data/ups/finalshp.shp -cl finalshp -crop_to_cutline /Users/rodrigo/Documents/tfg/data/data-raw/ASTER/water_v1/africa-asia/output/water_all_merged_resample.tif OUTPUT_water.tif


# multithread with gdalwarp
https://github.com/OpenDroneMap/ODM/issues/778

# create slope from dem
https://tilemill-project.github.io/tilemill/docs/guides/terrain-data/

gdaldem slope input_dem output_slope_map
            [-p use percent slope (default=degrees)] [-s scale* (default=1)]
            [-alg ZevenbergenThorne]
            [-compute_edges] [-b Band (default=1)] [-of format] [-co "NAME=VALUE"]* [-q]


gdaldem slope output_gdem_mercator.tif slope_gdem.tif -p -compute_edges -co COMPRESS=LZW


# reproject a tif file
gdalwarp -s_srs EPSG:3395 -t_srs EPSG:4326 -co COMPRESS=LZW -co BIGTIFF=YES slope_gdem_mercator.tif slope_gdem_4326.tif

-s_srs: source crs
-t_srs: output crs

#  COMPRESSION #

'''
There are many ways to compress an image. The main disnticntion between lossy
and lossless compression. When working with geo data is better to use a lossless
compression.

To compress with GDAL we need to use gdal_translate with the option -co

For me (idk much) the best option has been:
-co COMPRESS=LZW
-co PREDICTOR=2

Example:
gdal_translate -co "COMPRESS=LZW" -co "PREDICTOR=2" input.tif output_compressed.tif

info gdal: https://gdal.org/drivers/raster/gtiff.html#creation-options
more info: https://gis.stackexchange.com/questions/345883/how-to-decrease-raster-file-size

'''
