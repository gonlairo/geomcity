library(sf)
library(raster)


ups_4326_radius = st_read('/Users/rodrigo/Documents/tfg/data/ups/all_radius.shp')
shpactual = read.csv('/Users/rodrigo/Documents/tfg/data/ups/metrics_actual.csv')
shppotential = read.csv('/Users/rodrigo/Documents/tfg/data/ups/metrics.csv')

year = 1:21
shpactual$year = year
shpactual$id = all_radius$id_x
shpactual$cohesion_potential = shppotential$cohesion
shpactual$prod = all_radius$sum_lights/all_radius$area
write.csv(shpactual, "/Users/rodrigo/Documents/tfg/data/ups/actualpotentialmetrics.csv")

df = ups_4326_radius %>% st_drop_geometry() %>%
  select(-c(id_y, density90, radius)) %>%
  rename(id = id_x) %>%
  mutate(prod_area = sum_lights/area)

df$dist = shpactual$interdist
df$pot_dist = shppotential$interdist
df$compactness = shpactual$cohesion
df$pot_compactness = shppotential$cohesion
df$id = as.factor(df$id)
str(df)


shpaa = st_read('/Users/rodrigo/Documents/tfg/data/shp/shp_AA_final.shp') %>%
  select(id, cntry_x, subregn, contnnt) %>%
  st_drop_geometry()

df_all = inner_join(df, shpaa, by = c("country" = "cntry_x")) %>%
  fastDummies::dummy_cols(select_columns = c("contnnt", "subregn", "country"))


#########################
## ECONOMETRICS MODELS ## 
#########################

# (1) log(prod/area) = beta*compactness + fe_id + fe_time + error

# OLS
ols = lm(log(prod_area) ~ compactness + id + year - 1, data = df)
summary_ols = summary(ols)
# Result:
# (+) 0.05 with t-value 5.7 (***)

fixed = plm::plm(log(prod_area) ~ compactness, data = df, index = c("id", "year"),  model = "within")
summary(fixed)
fixef(fixed)

# robust standard errors
coeftest(fixed, vcov. = vcovHC, type = "HC1")

#############################################

# FIRST STAGE
fs = lm(compactness ~ pot_compactness + id + year - 1, data = df)
comptactness_hat = stats::predict(fs)
df$compactness_hat = comptactness_hat
summary_fs = summary(fs)
# Result: (+) 0.024 with t-value 2.639 (**)
 
#############################################

# REDUCED FORM
rf = ols = lm(log(prod_area) ~ pot_compactness + id + year - 1, data = df)
summary_rf = summary(rf)

# SECOND STAGE
ss = lm(log(prod_area) ~ compactness_hat + id + year -1, data = df)
summary_ss = summary(ss)

# IV  
iv <- AER::ivreg(log(prod_area) ~ compactness + id + year -1| pot_compactness + id + year - 1, data = df)
summary_iv = summary(iv)


ivplm = plm::plm(log(prod_area) ~ compactness | pot_compactness, data = df_all, 
                 index = c('id.x', 'year'), inst.method = "bvk", model = "within")
summary(ivplm)                     

ivplm2 = plm::plm(log(prod_area) ~ compactness + compactness*contnnt_Africa + compactness*contnnt_Asia - 1| pot_compactness*contnnt_Africa + pot_compactness*contnnt_Asia ,
                  data = df_all, 
                 index = c('id.x', 'year'), inst.method = "bvk", model = "within")
summary(ivplm2) 
coeftest(ivplm2, vcov = vcovHC, type = "HC1")



# (2) log(prod) = beta*interdist + gamma*log(area) + fe_id + fe_time + error

# fist stage
ivplm = plm::plm(dist ~ pot_dist,
                 data = df_all, 
                 index = c('id.x', 'year'), model = "within")
summary(ivplm)

ivplm = plm::plm(log(sum_lights) ~ dist + log(area)| pot_dist + log(area), data = df, 
                 index = c('id', 'year'), inst.method = "bvk", model = "within")
summary(ivplm)                     











