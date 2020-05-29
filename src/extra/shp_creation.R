library(sf)
library(dplyr)

# world shapefile with countries
wshp = st_read('/Users/rodrigo/Documents/tfg/data/raw/shapefiles/gadm36_levels_shp/gadm36_0.shp')

# AFRICA
africacodes = read.csv('/Users/rodrigo/Documents/tfg/data/raw/shapefiles/africa_codes.csv')
africaids = africacodes$id
AfricaShp = wshp[wshp$GID_0 %in% africaids ,]
plot(AfricaShp$geometry)
st_write(AfricaShp, dsn = '/Users/rodrigo/Documents/tfg/data/raw/shapefiles/continents/Africa.shp', delete_layer = TRUE )

# ASIA
asiacodes = read.csv('/Users/rodrigo/Documents/tfg/data/raw/shapefiles/asia_codes.csv')
asiaids = asiacodes$id
AsiaShp = wshp[wshp$GID_0 %in% asiaids ,]
plot(AsiaShp$geometry)
st_write(AsiaShp, dsn = '/Users/rodrigo/Documents/tfg/data/raw/shapefiles/continents/Asia.shp', delete_layer = TRUE )

# SPAIN
SpainShp = wshp[wshp$GID_0 == 'ESP' ,]
st_write(SpainShp, dsn = '/Users/rodrigo/Documents/tfg/data/raw/shapefiles/countries/Spain.shp', delete_layer = TRUE )


# GOAL SHAPEFILE (AFRICA + DEVELOPING ASIA)
asia_africa = read.csv('/Users/rodrigo/Documents/tfg/data/raw/shapefiles/asia_africa.csv')
asia_africaids = asia_africa$id
AsiaAfricaShp = wshp[wshp$GID_0 %in% asia_africaids ,]
colnames(AsiaAfricaShp)[1] = 'id'
colnames(AsiaAfricaShp)[2] = 'country'
rownames(AsiaAfricaShp) = NULL
AsiaAfricaShp = dplyr::left_join(AsiaAfricaShp, asia_africa, by = 'id')
plot(AsiaAfricaShp$geometry)
st_write(AsiaAfricaShp, dsn = '/Users/rodrigo/Documents/tfg/data/raw/shapefiles/continents/AsiaAfricaShp.shp', delete_layer = TRUE )


# Add "optimal" thresholds

shp = sf::st_read('/Users/rodrigo/Documents/tfg/data/data-raw/shapefiles/continents/final_threshold.shp')
ot = read.csv('/Users/rodrigo/Documents/tfg/data/thresholds/final_thresholds.csv')

shp$optim_threshold = ot$optim_threshold
shp$weird = ot$weird
shp$comnt = ot$comments
shp$why = ot$why

sf::st_write(shp, dsn = '//Users/rodrigo/Documents/tfg/data/shp/finalshp.shp', delete_layer = TRUE )

# next iteration


# Add "optimal" thresholds

shp = sf::st_read('/Users/rodrigo/Documents/tfg/data/shp/finalshp.shp')
ot = read.csv('/Users/rodrigo/Documents/tfg/data/thresholds/final_thresholds.csv')

shp$lower_thr = ot$lower_bound_threshold
shp$upper_thr = ot$upper_bound_threshold
sf::st_write(shp, dsn = '/Users/rodrigo/Documents/tfg/data/shp/shp_AF_final.shp', delete_layer = TRUE )

