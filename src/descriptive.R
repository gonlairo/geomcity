library(sf)
library(ggplot2)

path_all = '/Users/rodrigo/Documents/tfg/data/ups/all.shp'
allshp = st_read(path_all)

# Number of cities
length(unique(allshp$id)) #1809 unique urban areas

# Number of countries
length(unique(allshp$country)) #77 countries out of 80 (81 - South Sudan)

# countries that dont have cities in common:
# Bhutan
# Liberia
# Sierra Leone

# Compute the area of each polygon

allshp = allshp %>% st_set_crs(4326)
allshp$area = st_area(allshp) 
allshp$area = as.numeric(allshp$area)
allshp_area = allshp #[1:1005 ,]

# plot of the area
countries = unique(allshp$country)
for (country in countries) {
  temp_df = allshp[allshp$country == country , ]
  p = ggplot(temp_df, aes(x = year, y = area, group = id, color = id)) +
      geom_line() +
      ggtitle(country)
  output_path = paste0('/Users/rodrigo/Documents/tfg/output/areaplots/', country, '.png')
  ggsave(p, filename = output_path)
}
