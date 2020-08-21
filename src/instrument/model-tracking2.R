setwd("/Users/rodrigo/Documents/tfg")
library(sf)
library(raster)
library(dplyr)
library(purrr)
library(ggplot2)

library(plm)
library(lmtest)
library(sandwich)

# read 
ups_3395 = st_read('data/ups/ups_avg/ups_3395.gpkg') 

metrics_3395 = read.csv('data/ups/ups_avg/metrics_3395.csv') %>% 
  rename(cohesion = Cohesion) %>%
  mutate(year = as.factor(year),
         cohesion2  = cohesion**2,
         proximity2 = proximity**2,
         spin2 = spin**2)

metrics_pf_3395 = read.csv('data/ups/ups_avg/metrics_pf_3395.csv') %>%
  rename(pcohesion = Cohesion,
         pproximity = proximity,
         pspin = spin,
         pr = r,
         parea = A) %>%
  mutate(year = as.factor(year),
         pcohesion2 = pcohesion**2,
         pproximity2 = pproximity**2,
         pspin2 = pspin**2)

# bind ups_3395 and metrics_3395 and remove NA
df_join = list(ups_3395 %>% st_drop_geometry(), metrics_3395, metrics_pf_3395) %>%
  reduce(inner_join, by = c("id", "year")) %>%
  mutate(nlights = lights / areakm2)


# population
pop90 = st_read('data/ups/tracking-ucdb/ups_pop90_4326.gpkg') %>% st_drop_geometry()
pop00 = st_read('data/ups/tracking-ucdb/ups_pop00_4326.gpkg') %>% st_drop_geometry()
pop15 = st_read('data/ups/tracking-ucdb/ups_pop15_4326.gpkg') %>% st_drop_geometry()

pop_all = list(df_join,pop90, pop00, pop15) %>%
  reduce(left_join, by = c("id", "year")) %>%
  transmute(pop = coalesce(pop1990, pop2000, pop2015))

# join population with the rest
df_all = df_join %>%
  mutate(pop = pop_all$pop,
         poparea = pop / areakm2,
         id = as.factor(id)) 
