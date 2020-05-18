import math, random, os, time
from shapely.geometry import Point, Polygon, LineString


def polygon_intersect_y(poly, y_val):
    """
    Find the intersection points of a horizontal line at
    y =`y_val` with the Polygon `poly`.
    """
    #if y_val < poly.bounds[1] or y_val > poly.bounds[3]:
    #    raise ValueError('`y_val` is outside the limits of the Polygon.')

    if isinstance(poly, Polygon):
        poly = poly.boundary
        horiz_line = LineString([[poly.bounds[0], y_val],
                                 [poly.bounds[2], y_val]])

    pts = [pt.xy[0][0] for pt in poly.intersection(horiz_line)]
    pts.sort()
    pts_pairs = list(zip(pts, pts[1:]))
    return pts_pairs


def ConvertToGridPnts(ShpGeom_mp):


    mp_pntLst = []
    mp_featPntLst = []

    try:
        npols = len(ShpGeom_mp)
    except TypeError:
        #print('Not a multipolygon')
        npols = 1

    #print('number of polygons:' , npols)
    for i in range(npols):

        try:
            ShpGeom = ShpGeom_mp[i]
        except:
            ShpGeom = ShpGeom_mp
        # Get shape extent and extract bounding coordinates...
        extent = ShpGeom.bounds

        #---------------------------
        # LIST OF COORDINATES OF FEATURE VERTICES (for single part features)...
        pntLst = []   # stores feature array...
        subVLst = []

        ExteriorCoords = iter(ShpGeom.exterior.coords)    # get first polygon if we have a multipolygon

        pnt = next(ExteriorCoords)  # get point from array
        # for each part array...
        while pnt:

            # get point XY
            X, Y = pnt[0], pnt[1]
            subVLst.append([X,Y])  # add XY to list

            try:
                pnt = next(ExteriorCoords)  # get next point
            except StopIteration:
                break


        pntLst.append(subVLst)
        mp_pntLst.append(pntLst)
        subVLst = []

        #----------------------------------
        # GRID OF POINTS

        featPntLst = []   # list of coordinates of points in feature

        # feature area...
        a = ShpGeom.area

        # desired shape area in pixels...
        numPix = 10000

        # calculate pixel size...
        cellsize = (a / numPix)**.5

        # get min and max XY values
        minX, minY, maxX, maxY = extent[0], extent[1], extent[2], extent[3]

        # offset grid by half a pixel...
        minX -= cellsize / 2
        maxY += cellsize / 2

        # set current Y to maxY...
        Y = maxY

        # for each row...
        while Y >= minY:

            # get range of X values within which lie the inside of feature...
            rangeLst = polygon_intersect_y(ShpGeom_mp,Y)

            # set X to leftmost column
            X = minX

            # for each column
            while X <= maxX:

                # for each range of X values
                for x1,x2 in rangeLst:

                    # if current X is within range, point is in shape
                    if x1 <= X <= x2:
                        featPntLst.append([X,Y])   # at point to feature point list
                        break

                # X coordinate of next column
                X += cellsize

            # Y coordinate for next row...
            Y -= cellsize


        # remove points inside holes
        #print('number of rings in polygon', i + 1, ':', len(ShpGeom.interiors))


        if len(ShpGeom.interiors) > 0:

            removeids = []
            for i in range(len(featPntLst)):
                SInsidePnt = Point(featPntLst[i])

                for Interior in ShpGeom.interiors:
                    PInterior = Polygon(Interior)

                    if PInterior.contains(SInsidePnt):
                        removeids.append(i)

            featPntLst = [v for i, v in enumerate(featPntLst) if i not in removeids]
            #print("\npoints removed:", len(removeids))

        mp_featPntLst.append(featPntLst)

    # return feature XY list...
    return mp_pntLst, mp_featPntLst


'''
def interpointDistance(ptList): # requires list of XY coordinates of points in shape

    # number of points in shape...
    numPts = len(ptList)

    samplSize = 300    # number of points in sample
    samples = 30        # number of samples

    avgD = 0    # average interpoint distance

    # run specified number of samples...
    for t in range(samples):

        total_D = 0     # cumulative distance
        cnt = 0         # number of calculations

        # select a random sample of shape points...
        sampLst = random.sample(ptList, samplSize)

        # for each point in sample, calculate distance between it and
        # every other point...
        for pt1 in sampLst:

            # get coordinates of a point...
            X1 = pt1[0]
            Y1 = pt1[1]

            # calculate distance to all other points in sample...
            for pt2 in sampLst:

                # skip pt2 if it is the same as pt1...
                if pt1 == pt2: continue

                # get coord. of point from sample...
                X2 = pt2[0]
                Y2 = pt2[1]

                # calculate distance to pt1...
                dist = ((X1-X2)**2 + (Y1-Y2)**2)**.5

                # cumulative interpoint distance...
                total_D += dist

                # number of calculations...
                cnt += 1

        # average interpoint distance...
        avgD += (total_D / cnt) / samples
    print('r:', avgD)
    return avgD
'''
