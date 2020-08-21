setwd("/Users/rodrigo/Documents/tfg")
library(dplyr)
library(ggplot2)

# stats packages
library(plm)
library(lmtest)
library(sandwich)
library(stargazer)

# import data
df_final = read.csv("data/final/df_final_noNAF.csv")
df_final = df_final %>%
  mutate(compactness_m0     = (compactness - mean(compactness)),
         compactness_m0v1   = (compactness - mean(compactness))/ sd(compactness),
         pcompactness_m0    = (pcompactness - mean(pcompactness)),
         pcompactness_m0v1  = (pcompactness - mean(pcompactness)/ sd(pcompactness)),
         productivity_m0    = (productivity - mean(productivity)),
         productivity_m0v1  = (productivity_m0 - mean(productivity)) / sd(productivity),
         compactness2       = compactness**2,
         compactness2_m0    = compactness_m0**2,
         compactness2_m0v1  = compactness_m0v1**2,
         pcompactness2      = pcompactness**2,
         pcompactness2_m0   = pcompactness_m0**2,
         pcompactness2_m0v1 = pcompactness_m0v1**2) %>%
  #mutate(size = cut(mydata$Age, seq(0,30,5), right=FALSE, labels=c(1:6)))
  group_by(id) %>%
  mutate(small = any(areakm2 < 50),
         big = any(areakm2 >= 50)) %>%
  ungroup()

df_final_big = df_final %>%
  group_by(id) %>%
  filter(!any(areakm2 < 50)) %>%
  ungroup()

df_africa = df_final %>% filter(continent == "Africa")
df_asia = df_final %>% filter(continent == "Asia")
df_india = df_asia %>% filter(country == "India")
df_china = df_asia %>% filter(country == "China") 

####
source("src/models/regressions_rse.R")
source("src/models/iv.R")

continents = as.character(unique(df_final$continent))
regions = as.character(unique(df_final$region))
countries = c("India", "China", "Nigeria", "South Africa")

# ols and firs stage
formula = log(productivity) ~ pcompactness_m0
t = regressions_rse(df_final_big, formula = formula,
                    continents = continents, regions = regions, countries = countries, fstat = TRUE)

# intrumental variable (second stage)
formulaiv = log(productivity) ~ compactness_m0 | pcompactness_m0
tiv = iv(df_final_big, formula = formulaiv, continents = continents, regions = regions, countries = countries)

# second stage #
iv_fe_world <- plm(log(productivity) ~ pcompactness,
                data = df_africa,
                effect = c('twoways'),
                index = c('id', 'year'),
                inst.method = "bvk")
summary(iv_fe_world) 


#######################################################
#######################################################

# long differences #
df_first = df_china %>%
  group_by(id) %>%
  slice(1)

df_last = df_china %>%
  group_by(id) %>%
  slice(n())

df_ld = df_last - df_first
df_ld[, 1:6] = df_last %>% dplyr::select(1:6)
write.csv(df_ld, '/Users/rodrigo/Documents/tfg/data/final/df_china_ld.csv')


#df_ld_africa = df_ld %>% filter(continent == "Africa")
#df_ld_asia = df_ld %>% filter(continent == "Asia")
#df_ld_india = df_ld %>% filter(country == "India")
#df_ld_china = df_ld %>% filter(country == "China") 


fit = lm(log(productivity) ~ compactness,
         data = df_ld)
summary(fit)

lmtest::coeftest(fit, vcov = sandwich::vcovHC(fit, "HC1"))











