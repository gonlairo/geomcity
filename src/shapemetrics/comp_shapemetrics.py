import os
import pandas as pd
import numpy as np
import math, random, time, os, sys, string
import geopandas as gpd
from shapely.geometry import Polygon, Point, MultiPolygon
import r_shapemetrics
import interpointDistance

shp_path = '/Users/rodrigo/Documents/tfg/data/ups/potential_footprints.shp'
shpfile = gpd.read_file(shp_path)

npfs = shpfile.shape[0]
for i in range(npols):
    pf = shpfile['geometry'][i]
    vertexLst, featPntLst = r_shapemetrics.ConvertToGridPnts(pf)

    # COHESION #
    interdist = interpointDistance.interpointDistance(featPntLst[0])
    A = pf.area
    r = (A / math.pi)**.5       # radius of equal area circle (circle with area equal to shape area)
    circ_interD = r * .9054
    CohesionIndex = circ_interD / interdist

   shpfile['cohesion'][i] = CohesionIndex
    # OTHER METRICS #
   shpfile.to_file('/Users/rodrigo/Documents/tfg/data/ups/shapemetrics.shp')
