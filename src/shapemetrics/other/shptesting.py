import timeit

setup = '''
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.pyplot import figure
import math, random, time, os, sys, string
import geopandas as gpd
from shapely.geometry import Polygon, Point, MultiPolygon
import r_shapemetrics
import interpointDistance
import interpointDistanceNP

shp_path = '/Users/rodrigo/Documents/tfg/data/ups/potential_footprints.shp'
shpfile = gpd.read_file(shp_path)
pf = shpfile['geometry'][0]
vertexLst, featPntLst = r_shapemetrics.ConvertToGridPnts(pf)
featPntLstNP = np.array(featPntLst[0])
featPntLst1 = np.array(random.sample(featPntLst[0], 5000))
'''
distance_cy = timeit.timeit('interpointDistance.interpointDistance(featPntLst[0])', setup = setup, number = 10)
#distance_cyNP = timeit.timeit('interpointDistanceNP.interpointDistance(featPntLstNP)', setup = setup, number = 1)
distance_py = timeit.timeit('r_shapemetrics.interpointDistance(featPntLst[0])', setup = setup, number = 10)
print(distance_cy, distance_py)
print('distance_cy is {}x faster than distance_py'.format(distance_py/distance_cy))
