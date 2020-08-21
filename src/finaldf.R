# TRACKING 1
ups_3395 = st_read('data/ups/tracking-ucdb/ups_3395.gpkg') %>% mutate(year = as.character(year))
smetrics_3395 = read.csv('data/ups/tracking-ucdb/shapemetrics/sm_ups_3395.csv') %>% mutate(year = as.character(year))
smetrics_pf_3395 = read.csv('data/ups/tracking-ucdb/shapemetrics/sm_pf_3395.csv') %>% mutate(year = as.character(year))

# bind ups_3395 and metrics_3395 and remove NA
df_all = list(ups_3395, smetrics_3395, smetrics_pf_3395) %>%
  reduce(inner_join, by = c("id", "year")) %>%
  mutate(productivity = lights / areakm2)

df_finalt1 = df_all %>%
  filter_at(vars(pcohesion), all_vars((.) != 0)) %>%
  filter(!country %in% c("Honk Kong", "Japan", "Taiwan", "South Korea")) %>%
  mutate(id = as.factor(id),
         year = as.factor(year))

# TRACKING 2
ups_3395 = st_read('data/ups/tracking-centroid/ups_3395.gpkg') %>% mutate(year = as.character(year))
smetrics_3395 = read.csv('data/ups/tracking-centroid/shapemetrics/sm_ups_3395.csv') %>% mutate(year = as.character(year))
smetrics_pf_3395 = read.csv('data/ups/tracking-centroid/shapemetrics/sm_pf_3395.csv')%>% mutate(year = as.character(year))

# bind ups_3395 and metrics_3395 and remove NA
df_all = list(ups_3395, smetrics_3395, smetrics_pf_3395) %>%
  reduce(inner_join, by = c("id", "year")) %>%
  mutate(productivity = lights / areakm2)

df_finalt2 = df_all %>%
  filter_at(vars(pcohesion), all_vars((.) != 0)) %>%
  filter(!country %in% c("Honk Kong", "Japan", "Taiwan", "South Korea")) %>%
  mutate(id = as.factor(id),
         year = as.factor(year))

# asia from t1 and africa from t2
asiat1 = df_finalt1 %>%
  filter(continent == "Asia") %>%
  mutate(id = as.numeric(id)) %>%
  select(-city)

africat2 = df_finalt2 %>%
  filter(contnnt == "Africa") %>%
  mutate(id = as.numeric(id)) %>%
  rename(continent = contnnt,
         region = subregn)

africat2$id = africat2 %>%
  group_indices(id)

africat2$id = africat2$id + max(asiat1$id)

finalups = rbind(asiat1, africat2) %>%
  select(id, year, country, region, continent)
st_write(finalups, '/Users/rodrigo/Documents/tfg/data/final/finalups.gpkg')
finaldf = finalups %>% st_drop_geometry()
write.csv(finaldf, '/Users/rodrigo/Documents/tfg/data/final/df_final.csv', row.names = FALSE)
  
