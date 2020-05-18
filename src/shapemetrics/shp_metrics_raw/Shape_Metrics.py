# AUTHOR: J
# DATE: July 23, 2009
# PURPOSE: This script calculates 12 different metrics that quantify a specific
# aspect of a polygon's shape. A normalized version of each metric is provided
# that is not influenced by the polygon's area. Normalization is done using
# the circle which is the most compact shape possible for a given area.

# Bug fix (17-Dec-09): generation of perimeter point list failed for shapes
#     with large coordinate values (far from origin). Corrected by shifting extent
#     toward origin (0,0).


import math,random,time,Helper_tool,os,arcgisscripting, sys, string

# MAIN

try:

    # Create the geoprocessor...
    gp = arcgisscripting.create(10)
    gp.SetProduct("ArcView")

    # Allow output files to be overwritten...
    gp.OverwriteOutput = 1

    # script parameters...

    shapes = sys.argv[1]
    output = sys.argv[2]
    metrics = sys.argv[3]
    edge_width = sys.argv[4]

##    shapes = r"C:\Temp\polygon.shp"
##    output = r"C:\Temp\shapeMetricsTest8.shp"
##    metrics = "Proximity"
##    edge_width = "0"



    if edge_width == '#':
        if "Interior" in metrics:
            gp.AddError("\nEDGE WIDTH MUST BE SPECIFIED TO CALCULATE INTERIOR INDEX")
            sys.exit(1)
    else:
        edge_width = float(edge_width)




    #--------------------------------------------


    #print "begin"

    gp.CopyFeatures(shapes,output)

    # Set output coordinate system...
    gp.OutputCoordinateSystem = output

    #-------------------------------------
    # SET UP TEMP WORKSPACE...

    TempWS = "C:\\Shape_Metrics_Temp"

    if not os.path.exists(TempWS):     # temp folder does not exist

        os.makedirs(TempWS)

        gp.workspace = TempWS

    # ADD FIELDS TO ATTRIBUTE TABLE...

    metrics = metrics.split(";")

    gp.AddMessage(metrics)

    for metric in metrics:
        gp.addfield(output,metric,"double")
        norm_metric = "n%s" % metric
        gp.addfield(output,norm_metric,"double")


    #---------------------------------------------------------------------------
    # CALCULATE METRICS FOR EACH FEATURE IN FEATURE CLASS...

    IDField = gp.Describe(shapes).OIDFieldName  # Feature ID field name

    shapeField = gp.Describe(shapes).ShapeFieldName

    #cur = gp.UpdateCursor(output)  Zmena nacita se vstupni SHP nikoliv vystupni, ikdyz ten ma byt stejny
    cur = gp.UpdateCursor(output)
    row = cur.Next()

    while row:

        metric_dct = {}

        ID = row.GetValue(IDField)

        s = time.clock()

        #print"\n",ID
        gp.AddMessage("\nProcessing feature %s..." % ID)

        #---------------------------------------------------------------------------
        # GET SHAPE GEOMETRY INFO...

        # Get geometry object for feature...
        ShpGeom = row.GetValue(shapeField) # Create geometry object for feature

        #---------------------------
        # SKIP MULT-PART FEATURES (USER SHOULD USE MULTIPART TO SINGLEPART TOOL)...
        if ShpGeom.PartCount > 1:
            row = cur.next()
            #print "Multi-part feature, cannot analyze"
            gp.AddMessage("\tMulti-part feature, cannot analyze")
            continue
        #---------------------------

        # Get shape area and perimeter...
        A = ShpGeom.Area             # area of feature
        P = ShpGeom.Length           # perimeter of feature

        # Get shape true centroid and extract coordinates...
        # centroidXY = ShpGeom.TrueCentroid
        centroidXY = ShpGeom.Centroid     # coordinates of true centroid of shape
        # centroidXY = centroidXY.string.split(" ")
        # centroidXY = [[float(centroidXY[0]), float(centroidXY[1])]]
        # ZD> misto pole se musi pouyit vsude v nasledujicim kodu centroidXY.X,centroidXY.Y

        #---------------------------------------------------------------------------
        # EQUAL AREA CIRCLE PARAMETERS...

        # Equal area circle radius...
        r = (A / math.pi)**.5       # radius of equal area circle (circle with area equal to shape area)
        p = 2 * math.pi * r         # Equal area circle perimeter

        #---------------------------------------------------------------------------
        # SECTION 1: GET LIST OF COORDINATES OF PERIMETER VERTICES

        # feature grid text file...
        gridTxtFile = "%s\\grid.txt" % TempWS

        # use custom tool to get XY list for shape vertices;
        # create grid text file for feature...

        vertexLst, featPntLst, cellsize, x_offset, y_offset = Helper_tool.ConvertToGridPnts(ShpGeom, gridTxtFile)

        # centroid coordinates
        # orig.  Xc, Yc = centroidXY[0][0]-x_offset, centroidXY[0][1]-y_offset
        # ZD zmena na
        Xc, Yc = centroidXY.X-x_offset, centroidXY.Y-y_offset

        #---------------------------------------------------------------------------
        # SECTION 2: THE COHESION INDEX...

        if "Cohesion" in metrics:

            # custom tool calculates approx. average interpoint distances between
            # samples of points in shape...
            shp_interD = Helper_tool.interpointDistance(featPntLst)

            # average interpoint distance for equal area circle...
            circ_interD = r * .9054

            # cohesion index is ratio of avg interpoint distance of circle to
            # avg interpoint distance of shape...
            CohesionIndex = circ_interD / shp_interD

            #print "Cohesion = %s" % (CohesionIndex),
            #print shp_interD

            metric_dct["Cohesion"] = [shp_interD,CohesionIndex]
            gp.AddMessage("\tCohesion calculated...")

        #------------------------------------------------------------------------------
        # SECTION 3: PROXIMITY INDEX (PROXIMATE CENTER AND GET DISTANCE TO PROXIMATE CENTER)...
        #   requires Section 2 (generate area points list)
        #   requires Section 4 (determine max window and number of iterations)

    ##    # Locate the proximate center (the point with the minimum distance to all other points)
    ##
    ##    # custom tool outputs average distance from all points to proximate center
    ##    # and XY coordinates of proximate center...
    ##    D_to_Center,centXY = Helper_tool.findCenter(inPt_XYLst,"Proximate",bndCoord)
    ##

        if "Proximity" in metrics or "Exchange" in metrics:

            #--------------------
            # Get average distance from all feature points to center...

            # NOTE: THE CENTROID IS CURRENTLY USED AS THE CENTER

            # calculate distance of feature points to center...
            # ZD change no list
            #orig:D_to_Center, EAC_pix = Helper_tool.proximity(featPntLst,[Xc,Yc],r)
            D_to_Center, EAC_pix = Helper_tool.proximity(featPntLst,Xc,Yc,r)


            # avg distance to center for equal area circle...
            circD = r * (2.0/3.0)

            if "Proximity" in metrics:

                # proximity index (circle / shape)...
                ProximityIndex = circD / D_to_Center
                #print "Proximity Index = %s" % (ProximityIndex),
                #print D_to_Center

                metric_dct["Proximity"] = [D_to_Center,ProximityIndex]
                gp.AddMessage("\tProximity calculated...")

            if "Exchange" in metrics:

                # area exchange index
                inArea = EAC_pix * cellsize**2
                areaExchange = inArea / A

                #print "Area Exchange Index = %s" % areaExchange

                metric_dct["Exchange"] = [inArea,areaExchange]
                gp.AddMessage("\tExchange calculated...")

        #------------------------------------------------------------------------------
        # SECTION 4: THE SPIN INDEX (RELATIVE MOMENT OF INERTIA)...

        if "Spin" in metrics:

            # custom tool calculates moment of inertia for shape...
            # ZD another calling, no list
            # shpMOI = Helper_tool.spin(featPntLst,[Xc,Yc])

            shpMOI = Helper_tool.spin(featPntLst,Xc,Yc)

            # moment of inertia for equal area circle...
            circ_MOI = .5 * r**2

            # calculate spin index (circle / shape)...
            Spin = circ_MOI / shpMOI

            #print "Relative Moment of Inertia Index = %s" % (Spin),
            #print shpMOI

            metric_dct["Spin"] = [shpMOI,Spin]
            gp.AddMessage("\tSpin calculated...")

        #------------------------------------------------------------------------------
        # SECTION 5: THE PERIMETER INDEX...

        if "Perimeter" in metrics:

            # perimeter index (circle / shape)
            PerimIndex = p / P          # The Perimeter Index

            #print "Perimeter Index = " + str(PerimIndex),
            #print P

            metric_dct["Perimeter"] = [P,PerimIndex]
            gp.AddMessage("\tPerimeter calculated...")

        #------------------------------------------------------------------------------
        # SECTION 6: GENERATE LIST OF POINTS UNIFORMLY DISTRIBUTED ALONG PERIMETER...

        if "Depth" in metrics or "Girth" in metrics or "Dispers_" in metrics or "Interior" in metrics:

            # get list of points evenly distributed along perimeter...
            perimPntLst = Helper_tool.PerimeterPnts(vertexLst, 500)

            #------------------------------------------------------------------------------
            # SECTION 7: CALCULATE DISTANCE OF INTERIOR SHAPE POINTS TO PERIMETER POINTS...

            # custom tool calculates distance of each interior point to nearest perimeter point...
            pt_dToE = Helper_tool.pt_distToEdge(featPntLst,perimPntLst)

        #------------------------------------------------------------------------------
        # SECTION 8: THE DEPTH INDEX...

        if "Depth" in metrics:

            # custom tool calculates average distance from interior pixels to nearest edge pixels...
            shp_depth = Helper_tool.depth(pt_dToE)

            # depth for equal area circle...
            EAC_depth = r / 3

            # calculate depth index (shape / circle)...
            depthIndex = shp_depth / EAC_depth

            #print "Depth Index = %s" % (depthIndex),
            #print shp_depth

            metric_dct["Depth"] = [shp_depth,depthIndex]
            gp.AddMessage("\tDepth calculated...")

        #------------------------------------------------------------------------------
        # SECTION 9: THE GIRTH INDEX (MAX INSCRIBED CIRCLE)...

        if "Girth" in metrics:

            # custom tool calculates shape girth (distance from edge to innermost point)
            # and outputs list position of innermost point...
            shp_Girth = Helper_tool.girth(pt_dToE)

            # calculate girth index (shape / circle)...
            girthIndex = shp_Girth / r      # girth of a circle is its radius

            #print "Girth Index = %s" % (girthIndex),
            #print shp_Girth

            metric_dct["Girth"] = [shp_Girth,girthIndex]
            gp.AddMessage("\tGirth calculated...")

        #-------------------------------------------------------------------------------
        # SECTION 14: THE VIABLE INTERIOR INDEX - the area of the shape that is farther than
        # the edge width distance from the perimeter.

        if "Interior" in metrics:

            interiorArea = Helper_tool.Interior(pt_dToE, edge_width)
            interiorArea *= cellsize**2

            circ_interiorArea = math.pi * (r - edge_width)**2

            interiorIndex = interiorArea / circ_interiorArea

            metric_dct["Interior"] = [interiorArea, interiorIndex]
            gp.AddMessage("\tViable interior calculated...")
            #print "Interior index calculation complete"

        #------------------------------------------------------------------------------

        # SECTION 10 THE DISPERSION INDEX (average distance between proximate center and edge points)...

        ## NOTE: THE CENTROID IS USED AS THE CENTER

        if "Dispers_" in metrics:

            # custom tool calculates average distance between proximate center and edge points...
            dispersionIndex, dispersion = Helper_tool.dispersion([Xc, Yc],perimPntLst[0])

            #print "Dispersion = %s" % (dispersionIndex)

            metric_dct["Dispers_"] = [dispersion,dispersionIndex]
            gp.AddMessage("\tDispersion calculated...")

        #------------------------------------------------------------------------------
        # SECTION 11: THE DETOUR INDEX (CONVEX HULL)..

        if "Detour" in metrics:

            # custom tool creates list of points in convex hull, outputs perimeter of hull...
            hullPerim = Helper_tool.ConvexHull(vertexLst[0])

            # calculate detour index (circle / shape)...
            detourIndex = p / hullPerim

            #print "Detour Index = %s" % (detourIndex),
            #print hullPerim

            metric_dct["Detour"] = [hullPerim,detourIndex]
            gp.AddMessage("\tDetour calculated...")

        #------------------------------------------------------------------------------
        # SECTION 12: THE RANGE INDEX (RADIUS OF MINIMUM CIRCUMSCRIBED CIRCLE)...

        if "Range" in metrics:

            # custom tool identifies perimeter points that are farthest apart, outputs
            # distance between furthermost points...
            circumCircD = Helper_tool.Range(vertexLst[0])

            # calculate range index (circle / shape)
            rangeIndex = (2*r) / circumCircD

            #print "Range Index = %s" % (rangeIndex),
            #print circumCircD

            metric_dct["Range"] = [circumCircD,rangeIndex]
            gp.AddMessage("\tRange calculated...")

        #-------------------------------------------------------------------------------
        # SECTION 13: THE TRAVERSAL INDEX (USING INTERIOR PATHS)

        if "Traversal" in metrics:

            # get list of points evenly distributed along perimeter...
            perimPntLst = Helper_tool.PerimeterPnts(vertexLst, 60)

            # calculate average traversal distance for shape...
            fAvgD =  Helper_tool.traversal_D(perimPntLst)

            # average traversal distance for equal area circle...
            circAvgD = 4*r/math.pi

            # normalized traversal index...
            traversal = circAvgD/fAvgD

            #print "traversal = %s" % (traversal),
            #print fAvgD

            metric_dct["Traversal"] = [fAvgD,traversal]
            gp.AddMessage("\tTraversal calculated...")



        #-------------------------------------------------------------------------------

        e = time.clock()
        #print "completed in %s seconds" % (e-s)
        gp.AddMessage("\tAnalysis completed in %s minutes\n" %((e-s)/60))


        for metric in metric_dct:
            value = metric_dct[metric][0]
            normValue = metric_dct[metric][1]
            normName = "n%s" % metric
            row.SetValue(metric,value)
            row.SetValue(normName,normValue)

        cur.UpdateRow(row)

        row = cur.Next()



    del cur,row

except:

    import traceback
    tb = sys.exc_info()[2]
    tbinfo = traceback.format_tb(tb)[0]

    gp.AddError(tbinfo)
    gp.AddError(sys.exc_type)
    gp.AddError(sys.exc_value)

    sys.exit(1)
