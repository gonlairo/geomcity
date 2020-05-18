

import math, random, time, os, sys, string
import geopandas as gpd
import mp_helper_tool_rodrigo


shp_path = '/Users/rodrigo/Documents/tfg/cities/data/created/shp/rings.shp'
shpfile = gpd.read_file(shp_path)
geometry = shpfile['geometry']
ShpGeom = geometry[1]

vertexLst, featPntLst, cellsize = mp_helper_tool_rodrigo.ConvertToGridPnts(ShpGeom)


#shp_interD = helper_tool_rodrigo.interpointDistance(featPntLst)
#print('featPntLst', featPntLst)
#print(shp_interD)
