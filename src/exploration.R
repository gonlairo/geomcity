# Summary statistics
# summary of spanish raster
hist(ntl_esp_maskc, col = "green", breaks = c(1,2,3,4,5,10,20,30,40,50,60,70))
raster::summary(ntl_esp_maskc)

# summary of the threshold raster
urban = raster::cellStats(area(ntl_city, na.rm = TRUE), stat = sum) # 34,577.83 km2
total = raster::cellStats(area(ntl_esp_maskc, na.rm = TRUE), stat = sum) # 496,468.9 km2
urban_perc = urban/total*100 # 6.96%