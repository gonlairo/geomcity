# Summary statistics
# summary of spanish raster
hist(ntl_esp_maskc, col = "green", breaks = c(1,2,3,4,5,10,20,30,40,50,60,70))
raster::summary(ntl_esp_maskc)

# summary of the threshold raster
urban = raster::cellStats(area(ntl_city, na.rm = TRUE), stat = sum) # 34,577.83 km2
total = raster::cellStats(area(ntl_esp_maskc, na.rm = TRUE), stat = sum) # 496,468.9 km2
urban_perc = urban/total*100 # 6.96%

# other stuff

#pols_allinfo = urban_polygons@polygons[[1]]  # info: plotOrder, area, ID, labpt(centroid), coords
#pols = pols_allinfo@Polygons                  # info: pols_allinfo - plotOrder

# plotting
#plot(urban_polygons)
#plot(pols[[2]]@coords)


# look into
# https://github.com/rspatial/raster/blob/master/R/rasterToPolygons.R
# https://www.rdocumentation.org/packages/sp/versions/1.3-2/topics/aggregate

# change function of a package:
# trace(raster::rasterToPolygons, edit = TRUE)

# pols_allinfo = urban_polygons@polygons[[1]]  # info: plotOrder, area, ID, labpt(centroid), coords
# pols = pols_allinfo@Polygons                  # info: pols_allinfo - plotOrder
# how to get the 100 polygon
# urban_polygons@polygons[[100]]@Polygons[[1]])

# Info about types of objects:
# class(urban_boundaries) = "SpatialPolygonsDataFrame" (sp)
# class(pols_allinfo) = "Polygons" (sp)
# class(pols) = "list"


# aggregate with maptools: https://cran.r-project.org/web/packages/maptools/maptools.pdf
# https://rdrr.io/cran/maptools/man/unionSpatialPolygons.html
# map overlay
# https://cran.r-project.org/web/packages/sp/vignettes/over.pdf

## WRITE RASTER##
#setwd("/Users/rodrigo/Documents/tfg/cities/data/created")
#rgdal::writeOGR(urban_polygons, dsn = '.', layer = "try", driver = "ESRI Shapefile")


# Thoughts:
# There are very small cities. I should disgreard those cities for my project?
# How many cities (urban markets?) do we have? Comparison with GHSL?
# Should we agregate polygons (raster::aggregate) that are close together (1,2,4,8 km)?
# If we do it, should we do it after or before we use rasterToPolygons?


#https://stackoverflow.com/questions/12196440/extract-feature-coordinates-from-spatialpolygons-and-other-sp-classes?noredirect=1&lq=1
#converted = ggplot2::fortify(urban_polygons)

