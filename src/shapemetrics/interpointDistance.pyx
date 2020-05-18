import random

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
    print('cy:' , avgD)
    return avgD
