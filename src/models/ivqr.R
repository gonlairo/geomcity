setwd("/Users/rodrigo/Documents/tfg")
library(dplyr)
library(ggplot2)

# stats packages
library(stargazer)
# import data
df_final = read.csv("data/final/df_final_noNAF.csv")
df_africa = df_final %>% filter(continent == "Africa")
df_asia = df_final %>% filter(continent == "Asia")
df_india = df_asia %>% filter(country == "India")
df_china = df_asia %>% filter(country == "China") 


# INSTRUMENTAL VARIABLE QUANTILE REGRESSION #
source('/Users/rodrigo/Documents/tfg/src/models/ivqr/rq.ivpanelR.R')
# dummies per year 


# coefficients
bhat = rq.fit.ivpanel(d = df_india$compactness, exo = dummies_year,
                      iv = df_india$pcompactness, y = log(df_india$productivity) , s = df_india$id, tau = 0.5)
bhat = round(bhat, 3)
#standard errors
bsehat = rq.se.ivpanel(bhat = bhat, d = df_india$compactness, exo =dummies_year,
                       iv = df_india$pcompactness, y = log(df_india$productivity), s = df_india$id, tau = 0.5) 
bsehat = round(bsehat,3)  

# results
n = length(unique(df_india$id))
colnames(bsehat) = c("endog", "exog", rep("ie", n-1), "int") # ie: individual effects
rownames(bsehat) = c("beta", "se")                           # se: standard errors
print(bsehat)


# create function to compute IVQR and standard errors
ivqr = function(df, y, time_dummies, endogenous, iv, id, tau){
  #d   = df$endogenous
  #exo = time_dummies
  #iv  = df$iv
  #s  = df$id
  
  d = df_india$compactness_m0
  exo = dummies_india
  iv = df_india$pcompactness_m0
  y = log(df_india$productivity)
  s = df_india$id
  # estimate ivqr coefficients (1 endog + 21 time + (length(id) -1) fe + 1 intercept)
  bhat = rq.fit.ivpanel(d = d, exo = exo, iv = iv, y = log(y) , s = s, tau = tau)
  bhat = round(bhat, 3)
  
  # compute standard errors
  bsehat = rq.se.ivpanel(bhat = bhat, d = d, exo = exo, iv = iv, y = log(y), s = s, tau = tau) 
  bsehat = round(bsehat,3)
  return(list(bhat, bsehat))
}



source('/Users/rodrigo/Documents/tfg/papers/methodology/paneldata/IVQR/lamarche2009/raw/rq.ivpanel.R')
library(MASS)
df_try = df_asia
dummies_year = fastDummies::dummy_cols(df_try$year)[,-1]
d = as.matrix(df_try$compactness)
exo = as.matrix(dummies_year)
iv = as.matrix(df_try$pcompactness)
y = as.matrix(df_try$productivity)
s = as.matrix(df_try$id)

keep = vector('list')
for (t in c(0.1, 0.2, 0.5, 0.7, 0.9)) {
  # coefficinets
  print(t)
  bhat = rq.fit.ivpanel(d = d, exo = exo, iv = iv, y = log(y), s = s, tau = t)
  #bhat = round(bhat, 3)
  
  # compute standard errors
  bsehat = rq.se.ivpanel(bhat = bhat, d = d, exo = exo, iv = iv, y = log(y), s = s, tau = t) 
  #bsehat = round(bsehat,3)
  keep[[as.character(t)]] = bsehat
}


for (i in 1:length(keep)) {
  bhat = keep[[i]][1,][1]
  se   = keep[[i]][2,][1]
  imp = c(bhat, se)
  print(imp)
  print(bhat/se)
}







