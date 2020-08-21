# compute population
setwd("/Users/rodrigo/Documents/tfg/")
library(raster)
library(sf)
library(dplyr)

path_pols = 'data/ups/track_other/ups_4326.gpkg'
pols = st_read(path_pols)

# YEAR 1990 #

path_ghsl_pop1990 = 'data/data-raw/GHSL/population/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0/GHS_POP_E1990_GLOBE_R2019A_4326_9ss_V1_0.tif'
rpop = raster(path_ghsl_pop1990)

pols1990 = pols %>%
  select(id, year, geom) %>%
  filter(year %in% c("1992"))
  
pols1990$pop1990 = NA
npols = nrow(pols1990)
for (i in 1:npols){
  pop_clip1 = raster::crop(rpop, pols1990[i,])
  pop_clip2 = raster::mask(pop_clip1, pols1990[i,])
  pop = raster::cellStats(pop_clip2, sum)
  pols1990$pop1990[i] = pop
}

st_write(pols1990, 'data/ups/track_other/ups_pop90_4326.gpkg')


# 2000

path_ghsl_pop2000 = 'data/data-raw/GHSL/population/GHS_POP_E2000_GLOBE_R2019A_4326_9ss_V1_0/GHS_POP_E2000_GLOBE_R2019A_4326_9ss_V1_0.tif'
rpop = raster(path_ghsl_pop2000)

pols2000 = pols %>%
  select(id, year, geom) %>%
  filter(year %in% c("2000"))

pols2000$pop2000 = NA
npols = nrow(pols2000)
for (i in 1:npols){
  pop_clip1 = raster::crop(rpop, pols2000[i,])
  pop_clip2 = raster::mask(pop_clip1, pols2000[i,])
  pop = raster::cellStats(pop_clip2, sum)
  pols2000$pop2000[i] = pop
}

st_write(pols2000, 'data/ups/track_other/ups_pop00_4326.gpkg')

# 2015
path_ghsl_pop2015 = 'data/data-raw/GHSL/population/GHS_POP_E2015_GLOBE_R2019A_4326_9ss_V1_0/GHS_POP_E2015_GLOBE_R2019A_4326_9ss_V1_0.tif'
rpop = raster(path_ghsl_pop2015)

pols2015 = pols %>%
  select(id, year, geom) %>%
  filter(year %in% c("2011"))

pols2015$pop2015= NA
npols = nrow(pols2015)
for (i in 1:npols){
  pop_clip1 = raster::crop(rpop, pols2015[i,])
  pop_clip2 = raster::mask(pop_clip1, pols2015[i,])
  pop = raster::cellStats(pop_clip2, sum)
  pols2015$pop2015[i] = pop
}

st_write(pols2015, 'data/ups/ups_pop15_4326.gpkg')

# add to ups_3395.gpckg















