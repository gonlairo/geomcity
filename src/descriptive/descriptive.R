library(sf)
library(ggplot2)
library(dplyr)
library(patchwork)

#######################
####### GRAPHS ########
#######################

setwd('/Users/rodrigo/Documents/tfg/')
source('src/descriptive/theme_densisty.R')
df_all = read.csv('data/final/df_final.csv') %>%
  filter(!country %in% c("Hong Kong", "North Korea")) %>%
  filter(!region %in% c("NAF")) %>%
  mutate(compactness = 0.5*cohesion + 0.5*spin,
         pcompactness = 0.5*pcohesion + 0.5*pspin)

write.csv(df_all,'data/final/df_final_noNAF.csv', row.names = FALSE)
options(scipen=999) # remove scientific notation for graphs


######################
# NIGHT-LIGHT / AREA #
######################

p_all_ntl = ggplot(df_all, aes(x = productivity, group = continent, fill = continent, color = continent)) + 
  geom_density(alpha = 0.6) +
  ggtitle("Africa vs Asia\n\n") +
  xlab("\n nightlights/area \n") +
  theme_density()
p_all_ntl

# TIME (t) (1992, 2000, 2012)
df_reduced = df_all %>% 
  filter(year %in% c("1992", "2000", "2009")) %>%
  mutate(year = as.character(year))

pt_africa = ggplot(df_reduced %>% filter(continent == "Africa"), aes(x = productivity, group = year, fill = year)) +
  geom_density(aes(x=productivity, y=..scaled..), alpha = 0.5) +
  #geom_histogram(alpha = 0.4)+
  ggtitle("Africa") +
  xlab("\n nightlights/area \n\n") +
  theme_density()

pt_asia = ggplot(df_reduced %>% filter(continent == "Asia"), aes(x = productivity, group = year, fill = year)) +
  geom_density(aes(x=productivity, y=..scaled..), alpha = 0.5) +
  #geom_histogram(alpha = 0.4)+
  ggtitle("Asia")+
  xlab("\n nightlights/area \n") +
  theme_density()

ggpubr::ggarrange(pt_africa, pt_asia, ncol=2, nrow=1, common.legend = TRUE, legend = "bottom")
åggsave('output/plots/density_AA_time.png', height = 9, width = 20)

###############
# COMPACTNESS #
###############

p_all_compact = ggplot(df_all, aes(x = compactness, group = continent, fill = continent, color = continent)) + 
  geom_density(alpha = 0.6) +
  ggtitle("Africa vs Asia\n") +
  xlab("\n compactness \n") +
  theme_density()
p_all_compact

ggpubr::ggarrange(p_all_ntl, p_all_compact, ncol=2, nrow=1, common.legend = TRUE, legend = "bottom")
ggsave('output/plots/ntl_comp_AA.png')


###############
  # AREA #
###############

p_all = ggplot(df_all, aes(x = areakm2, group = continent, fill = continent, color = continent)) + 
  #geom_histogram() +
  geom_density(aes(x=areakm2, y=..scaled..), alpha = 0.6) +
  ggtitle("Africa vs Asia\n") +
  xlab("\n compactness \n") +
  xlim(0, 1000) +
  theme_density()
p_all
ggsave('output/plots/compactness.png')


#######################
####### MAPS ##########
#######################

shp = rgdal::readOGR('/Users/rodrigo/Documents/tfg/data/shp/shp_AA_final.shp')
shp_df = fortify(shp)

ggplot() + 
  geom_polygon(data = shp, aes(long, lat, group = group))




