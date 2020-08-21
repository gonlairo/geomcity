setwd("/Users/rodrigo/Documents/tfg")
library(dplyr)
library(ggplot2)
library(patchwork)
source('/Users/rodrigo/Documents/tfg/src/models/themes/theme_plots.R')

df_final = read.csv("/Users/rodrigo/Documents/tfg/data/final/df_final_noNAF.csv")
df_final = df_final %>%
  mutate(compactness2 = compactness**2) %>%
  group_by(id) %>%
  mutate(big = any(areakm2 > 100),
         small = any(areakm2 <= 100)) %>%
  ungroup()

df_africa = df_final %>% filter(continent == "Africa")
df_asia = df_final %>% filter(continent == "Asia")
df_india = df_asia %>% filter(country == "India")
df_china = df_asia %>% filter(country == "China") 

# graphs


pworld = ggplot(df_final, aes(x = compactness, y = productivity, color = continent)) +
  geom_point(alpha = .5) +
  theme_plots()
pworld


ggplot(df_final, aes(x=compactness, y=predict)) +
  geom_point() +
  facet_wrap(log(productivity) ~ compactness)

pasia = ggplot(df_asia, aes(x = compactness, y = productivity)) +
  geom_point() +
  theme_plots()


ggplot(df_final, aes(x = compactness, y = pcompactness,
                     group = region, color = region)) +
  geom_point() +
  theme_plots()


# quantile regression plots
source('/Users/rodrigo/Documents/tfg/src/models/themes/theme_plots.R')
quantile = read.csv('/Users/rodrigo/Documents/tfg/data/final/quantiles_IC.csv') %>%
  mutate(country = as.character(country))
library(ggplot2)

pindia = ggplot(quantile %>% filter(country == "India"), 
                aes(x = quantile, y = coef,
                ymin = coef - 1.96*sqrt(std_error), 
                ymax = coef + 1.96*sqrt(std_error))) +
  geom_line(size=1.5) +
  geom_ribbon(alpha = 0.2, color = "blue", size = 1) + 
  scale_x_continuous(breaks = scales::pretty_breaks(n = 8)) +
  xlab("\nquantile\n") +
  ggtitle("India") +
  theme_plots()
pindia

pchina = ggplot(quantile %>% filter(country == "China"), 
                aes(x = quantile, y = coef,
                ymin = coef - 1.96*std_error, 
                ymax = coef + 1.96*std_error)) +
  geom_line(size=1.5) +
  geom_ribbon(alpha = 0.2, color = "blue", size = 1) + 
  scale_x_continuous(breaks = scales::pretty_breaks(n = 8)) +
  xlab("\nquantile\n")+
  ggtitle("China") +
  theme_plots()
pchina

pindia + pchina
ggsave("/Users/rodrigo/Documents/tfg/output/plots/quantilesIC.png")


