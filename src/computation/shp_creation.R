library(sf)

# world shapefile with countries
wshp = st_read('/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/gadm36_levels_shp/gadm36_0.shp')


# AFRICA
africacodes = read.csv('/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/africa_codes.csv')
africaids = africacodes$id
AfricaShp = wshp[wshp$GID_0 %in% africaids ,]
plot(AfricaShp$geometry)
st_write(AfricaShp, dsn = '/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/continents/Africa.shp', delete_layer = TRUE )

# SPAIN
SpainShp = wshp[wshp$GID_0 == 'ESP' ,]
st_write(SpainShp, dsn = '/Users/rodrigo/Documents/tfg/cities/data/raw/shapefiles/countries/Spain.shp', delete_layer = TRUE )
