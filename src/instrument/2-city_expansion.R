#######################################################
############# MODEL OF CITY EXPANSION #################
#######################################################

# Two approaches: section 5.1 and appendix B.E
# if the city’s population continued to grow as it did between 1975 and 1990 and population density
# remained constant at its 1990 level, what would be the area occupied by the city in year t? 

setwd('/Users/rodrigo/Documents/tfg')
path_ucdb = 'data/data-raw/GHSL/ucdb/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0/GHS_STAT_UCDB2015MT_GLOBE_R2019A_V1_0.shp'
path_country_codes = 'data/data-raw/shapefiles/asia_africa.csv'

ucdb = st_read(path_ucdb)
country_codes = read.csv(path_country_codes)

ups = st_read('/Users/rodrigo/Documents/tfg/data/ups/ups_4326.gpkg') %>%
  filter(!str_detect(city, 'N/A')) %>%
  mutate(area = as.numeric(st_area(geometry))*1e-6)

ucdb_radii = ucdb %>%
  filter(CTR_MN_ISO %in% country_codes$id) %>%
  dplyr::select(CTR_MN_ISO, UC_NM_MN, 
                P75, P90, P00, B75, B90, B00) %>%
  mutate(density90 = P90 / B90) %>%
  rename(city = UC_NM_MN) %>%
  #st_drop_geometry() %>%
  mutate(pop_gr = (((P90/P75) ** (1/15)) - 1)) %>%
  na.omit() 

ucdb_radii = ucdb_radii[!duplicated(ucdb_radii$city) ,]
unique_cn_ups = as.character(unique(ups$city))
ucdb_radii_ups = ucdb_radii[ucdb_radii$city %in% unique_cn_ups ,]

lproj = vector('list')
years = c()
for (t in 2:22) {
  year = as.character(1990 + t)
  lproj[[year]] = ucdb_radii_ups$P90 * ((1 + ucdb_radii_ups$pop_gr) ** t)
  years = c(years, year)
}

df_r = as.data.frame(matrix(unlist(lproj), ncol = length(lproj)))
colnames(df_r) = years
df_r$density90 = ucdb_radii_ups$density90
df_r$city = ucdb_radii_ups$city

df_rr = reshape(df_r,
                #idvar     = "id",
                varying   = colnames(df_r)[1:(ncol(df_r) - 2)],
                v.names   = c("pop"),
                times     = colnames(df_r)[1:(ncol(df_r) - 2)],
                timevar   = 'year',
                direction = "long")

df_rr_ordered = df_rr[order(df_rr$id),]
rownames(df_rr_ordered) = NULL

# join and order: 1805 unique cities.
final = inner_join(ups, df_rr_ordered, by = c('city', 'year')) #%>% st_drop_geometry()
final$year = as.factor(final$year)
final$city = as.factor(final$city)

# P75 is 0, gr is infinite, and therfore pop is infinite
final = final[!final$pop == Inf ,]        # 3 cities
final = final[!final$density90 == Inf, ]  # 1 city


#####################################################################
#####################################################################

# FIRST APPROACH
# ln(area c,t) = alpha * log(pop_proj c,t) + beta * density1990 + fixed effects time + error c,t
fit = lm(formula = log(area) ~ log(pop) + log(density90) + year - 1, data = final)
summary(fit)
coef  = coefficients(fit)       # coefficients
resid = residuals(fit)          # residuals
pred  = predict(fit)            # fitted values
rsq   = summary(fit)$r.squared  # R-sq for the fit
se    = summary(fit)$sigma      # se of the fit

# get the radius: sqrt( predicted area / pi)
radius = sqrt(pred / pi)
final$radius = radius

# SECOND APPOACH
#log(area c,t) = fiexed effects city + fixed effects time + error c,t
fit2 = lm(formula = log(area) ~ city + year -1, data = final)

summary(fit2)
coef  = coefficients(fit2)       # coefficients
resid = residuals(fit2)          # residuals
pred  = predict(fit2)            # fitted values
rsq   = summary(fit2)$r.squared  # R-sq for the fit
se    = summary(fit2)$sigma      # se of the fit

radius2 = sqrt(pred / pi)
final$radius2 = radius2
final$id.y = NULL
st_write(final, "/Users/rodrigo/Documents/tfg/data/ups/all_radius.shp")