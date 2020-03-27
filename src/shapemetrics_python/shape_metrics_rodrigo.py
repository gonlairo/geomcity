

import math, random, time, os, sys, string
import geopandas as gpd
import helper_tool_rodrigo


shp_path = '/Users/rodrigo/Documents/tfg/cities/data/created/raster/reprojected.shp'
shpfile = gpd.read_file(shp_path)
geometry = shpfile['geometry']
ShpGeom = geometry[30]

#print(ShpGeom)
print('npoints', len(list(ShpGeom.exterior.coords)))

vertexLst, featPntLst, cellsize = helper_tool_rodrigo.ConvertToGridPnts(ShpGeom)


#shp_interD = helper_tool_rodrigo.interpointDistance(featPntLst)
#print('featPntLst', featPntLst)
#print(shp_interD)
