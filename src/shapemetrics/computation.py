import pandas as pd
import geopandas as gpd
import math, random, time, os, sys, string
from shapely.geometry import Polygon, Point, MultiPolygon, LineString
import shapemetrics

def shapemetrics_pol(polygon):
    
    featPntLst = shapemetrics.ConvertToGridPnts(polygon)
    centroid = polygon.centroid
    Xc, Yc = centroid.x, centroid.y
    A = polygon.area
    r = (A / math.pi)**.5       # radius of equal area circle (circle with area equal to shape area)
    # COHESION #
    interdist = shapemetrics.interpointDistance(featPntLst)
    circ_interD = r * .9054
    CohesionIndex = circ_interD / interdist
    # PROXIMITY #
    D_to_Center, EAC_pix = shapemetrics.proximity(featPntLst,Xc,Yc,r)
    # avg distance to center for equal area circle...
    circD = r * (2.0/3.0)
    # proximity index (circle / shape)...
    ProximityIndex = circD / D_to_Center
    # SPIN #
    shpMOI = shapemetrics.spin(featPntLst,Xc,Yc)
    # moment of inertia for equal area circle...
    circ_MOI = .5 * r**2
    # calculate spin index (circle / shape)...
    Spin = circ_MOI / shpMOI
    return A, r, CohesionIndex, ProximityIndex, Spin


shp_path = '/Users/rodrigo/Documents/tfg/data/ups/ups_avg/pf_vm/potential_footprints_3395.shp'
shpfile = gpd.read_file(shp_path)

#from joblib import Parallel, delayed
#num_cores = 4
#metrics = Parallel(n_jobs = num_cores, verbose = 1)(delayed(shapemetrics_pol)(pol) for pol in shpfile['geometry'][32937:32980])

for pol in shpfile['geometry'][32972:32974]:
    shapemetrics12 = shapemetrics_pol(pol)

# write to file
#metricsdf = pd.DataFrame(metrics, columns=['A', 'r','Cohesion', 'proximity', 'spin'])
#metricsdf.to_csv('/Users/rodrigo/Documents/tfg/data/ups/metrics_all.csv')
