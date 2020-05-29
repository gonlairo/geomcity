import math, random, os, time
from shapely.geometry import Point, Polygon, LineString

def ConvertToGridPnts(ShpGeom):

    featPntLst = []  
    extent = ShpGeom.bounds

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
    totalbound = 0
    while Y >= minY:

        # get range of X values within which lie the inside of feature...
        start = time.time()
        rangeLst = bounds(ShpGeom,Y)
        end = time.time()
        diff = end - start
        totalbound += diff

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
    print("bound time", totalbound)

    return featPntLst

def bounds(poly, y_val):
    bounds = []

    if isinstance(poly, Polygon):
        polyb = poly.boundary
        horiz_line = LineString([[polyb.bounds[0], y_val],
                                 [polyb.bounds[2], y_val]])

    mp = polyb.intersection(horiz_line)
    for i in range(len(mp) - 1):
        line = LineString([mp[i], mp[i + 1]])

        if poly.contains(line):
            bounds.append([mp[i].x, mp[i + 1].x])

    return bounds


cpdef float interpointDistance(list ptList): # requires list of XY coordinates of points in shape

    # number of points in shape...
    cdef int numPts = len(ptList)
    cdef int samplSize = 1000    # number of points in sample
    cdef int samples = 30        # number of samples

    cdef float avgD = 0    # average interpoint distance
    cdef float total_D
    cdef int cnt
    cdef list sampLst
    cdef list pt1
    cdef list pt2
    cdef float X1
    cdef float Y1
    cdef float X2
    cdef float Y2
    cdef int t
    cdef int i
    cdef int j
    cdef float dist
    cdef int lensampLst

    # run specified number of samples...
    for t in range(samples):

        total_D = 0     # cumulative distance
        cnt = 0         # number of calculations

        # select a random sample of shape points
        sampLst = random.sample(ptList, samplSize)

        # for each point in sample, calculate distance btw it & every other pnt

        lensampLst = len(sampLst)
        for i in range(lensampLst):

            # get coordinates of a point
            pt1 = sampLst[i]
            X1 = pt1[0]
            Y1 = pt1[1]

            # calculate distance to all other points in sample
            for j in range(lensampLst):

                # skip pt2 if it is the same as pt1
                pt2 = sampLst[j]
                if (pt1 == pt2): continue

                # get coord. of point from sample
                X2 = pt2[0]
                Y2 = pt2[1]

                # calculate distance to pt1
                dist = ((X1-X2)**2 + (Y1-Y2)**2)**.5

                # cumulative interpoint distance
                total_D += dist

                # number of calculations
                cnt += 1

        # average interpoint distance...
        avgD += (total_D / cnt) / samples
    return avgD

def proximity(featPntLst,centerX,centerY,r):

    Xc,Yc = centerX, centerY

    sumD = inPix = 0    # sum of distances

    # for each feature point...
    for X,Y in featPntLst:

        # distance to center...
        d = ((X-Xc)**2 + (Y-Yc)**2)**.5

        sumD += d

        # if distance < EAC radius, then pixel is in
        if d < r:
            inPix += 1  # count pixel

    # calculate average distance
    D_to_Center = sumD / len(featPntLst)

    return D_to_Center, inPix

def spin(XYLst,centroidX, centroidY):

    # XY coordiantes of shape centroid...
    Xc, Yc = centroidX, centroidY

    # sum of distance squared...
    sum_dsqr = 0

    # count of number of pixels...
    cnt = 0

    # for each shape point...
    for pt in XYLst:

        # XY coordiante of point...
        X, Y = pt[0], pt[1]

        # distance to center squared...
        dsqr = (X-Xc)**2+(Y-Yc)**2

        # sum of squared distances...
        sum_dsqr += dsqr

        # count of points...
        cnt += 1

    return sum_dsqr / cnt




###########################################################################
###########################################################################
###########################################################################

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

'''
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
'''
