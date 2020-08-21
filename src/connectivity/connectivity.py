import geopandas as gpd
import pandas as pd
import matplotlib.pyplot as plt
import osmnx as ox
import math
import csv


## helper functions (taken from osmnx pakage)

def project_gdf(gdf, to_crs=None, to_latlong=False):
    """
    Project a GeoDataFrame to UTM.
    Automatically chooses the UTM zone appropriate for its geometries'
    centroid. The simple calculation in this function works well for most
    latitudes, but won't work for some far northern locations like Svalbard
    and parts of far northern Norway.
    Parameters
    ----------
    gdf : geopandas.GeoDataFrame
        the gdf to be projected
    to_crs : dict or string or pyproj.CRS
        if not None, project to this CRS instead of to UTM
    to_latlong : bool
        if True, projects to settings.default_crs instead of to UTM
    Returns
    -------
    gdf_proj : geopandas.GeoDataFrame
        the projected GeoDataFrame
    """
    if len(gdf) < 1:
        raise ValueError("Cannot project an empty GeoDataFrame")

    # if to_crs was passed-in, use this value to project the gdf
    if to_crs is not None:
        gdf_proj = gdf.to_crs(to_crs)

    # if to_crs was not passed-in, calculate the centroid of the geometry to
    # determine UTM zone
    else:
        # else, project the gdf to UTM

        # calculate the centroid of the union of all the geometries in the
        # GeoDataFrame
        avg_longitude = gdf["geometry"].unary_union.centroid.x

        # calculate the UTM zone from this avg longitude and define the UTM
        # CRS to project
        utm_zone = int(math.floor((avg_longitude + 180) / 6.0) + 1)
        utm_crs = f"+proj=utm +zone={utm_zone} +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

        # project the GeoDataFrame to the UTM CRS
        gdf_proj = gdf.to_crs(utm_crs)
        #print(f"Projected GeoDataFrame to UTM-{utm_zone}")

        return gdf_proj

def project_geometry(geometry, crs=None, to_crs=None, to_latlong=False):
    """
    Project a shapely (Multi)Polygon from lat-lng to UTM, or vice-versa.
    Parameters
    ----------
    geometry : shapely.geometry.Polygon or shapely.geometry.MultiPolygon
        the geometry to project
    crs : dict or string or pyproj.CRS
        the starting coordinate reference system of the passed-in geometry,
        default value (None) will set settings.default_crs as the CRS
    to_crs : dict or string or pyproj.CRS
        if not None, just project to this CRS instead of to UTM
    to_latlong : bool
        if True, project from crs to lat-lng, if False, project from crs to
        local UTM zone
    Returns
    -------
    geometry_proj, crs : tuple
        the projected shapely geometry and the crs of the projected geometry
    """
    if crs is None:
        crs = 4326

    gdf = gpd.GeoDataFrame()
    gdf.crs = crs
    gdf["geometry"] = None
    gdf.loc[0, "geometry"] = geometry
    gdf_proj = project_gdf(gdf, to_crs=to_crs, to_latlong=to_latlong)
    geometry_proj = gdf_proj["geometry"].iloc[0]
    return geometry_proj, gdf_proj.crs



################################################################################
################################################################################
################################################################################

# read shapefile and keep only one year (2009)
shpfile = gpd.read_file('/Users/rodrigo/Documents/tfg/data/final/finalups_4326.gpkg')
shpfile2009 = shpfile[shpfile['year'] == "2009"].reset_index()

if len(shpfile2009) < 1:
    raise ValueError("Empty GeoDataFrame")


with open('/Users/rodrigo/Documents/tfg/data/ups/connectivity/mc.csv','w') as f1:
    writer = csv.writer(f1, delimiter=',',lineterminator='\n',)
    npols = shpfile.shape[0]
    for i in range(npols):

        if not (i % 100):
            print(i)


        try:
            pol = shpfile['geometry'][i]

            # reproject to calculate the area
            polutm, _ = project_geometry(pol)
            areapol = polutm.area

            G = ox.graph_from_polygon(pol, network_type = 'drive')

            country = shpfile.iloc[i,:]['country']
            output_path = '/Users/rodrigo/Documents/tfg/data/ups/connectivity/' + country + '/' + country + str(i) + ".graphml"

            ox.io.save_graphml(G, output_path)
            basic_stats = ox.basic_stats(G, area = areapol)
            print(basic_stats)

            writer.writerow([i] + list(basic_stats.values()))

        except:
            print("error", i)
            writer.writerow([i] + ["NA"])
