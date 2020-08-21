regressions_rse = function(df, formula, continents, regions, countries, fstat){
  # ALL
  fe_ols_world = plm(formula,
                     data = df,
                     effect = c('twoways'),
                     index = c('id', 'year'),
                     model = "within")
  vcov = vcovHC(fe_ols_world, type = "HC1")
  se.world = sqrt(diag(vcov))

  
  # CONTINENT
  lcont = vector("list")
  se.cont = vector("list")
  for (cont in continents) {
    data_cont = df %>% filter(continent == cont)
    fe_ols_cont = plm(formula,
                 data = data_cont,
                 effect = c('twoways'),
                 index = c('id', 'year'),
                 model = "within")
    vcov = sandwich::vcovHC(fe_ols_cont, type = "HC1")
    robust.se = sqrt(diag(vcov))
    
    lcont[[cont]] = fe_ols_cont
    se.cont[[cont]] = robust.se
  }
  
  # REGIONS
  lreg = vector("list")
  se.reg = vector("list")
  for (reg in regions) {
    data_reg = df %>% filter(region == reg)
    fe_ols_reg = plm(formula,
                 data = data_reg,
                 effect = c('twoways'),
                 index = c('id', 'year'),
                 model = "within")
    
    # robust standard errors
    vcov = sandwich::vcovHC(fe_ols_reg, type = "HC1")
    robust.se = sqrt(diag(vcov))
    
    lreg[[reg]] = fe_ols_reg
    se.reg[[reg]] = robust.se
  }
  
  # COUNTRIES
  lcount = vector("list")
  se.count = vector("list")
  for (count in countries) {
    data_count = df %>% filter(country == count)
    fe_ols_count = plm(formula,
                 data = data_count,
                 effect = c('twoways'),
                 index = c('id', 'year'),
                 model = "within")
    
    # robust standard errors
    vcov = sandwich::vcovHC(fe_ols_count, type = "HC1")
    robust.se = sqrt(diag(vcov))
    
    lcount[[count]] = fe_ols_count
    se.count[[count]] = robust.se
  }
  
  
  # WOLRD + CONTINENTS + REGIONS + COUNTRIES
  if (fstat) {
    f = c()
  } else {
    f = c("f")
  }
  table = stargazer(fe_ols_world, lcont, lreg, lcount,
            se = c(list(se.world), se.cont, se.reg, se.count),
            column.labels = c("ALL", continents, regions, countries),
            type = "text", align=TRUE,
            omit.stat = c("adj.rsq", f), df = FALSE,
            add.lines = list(c('City FE', rep("Yes", 1 + length(continents) + length(regions) + length(countries))),
                             c('Time FE', rep("Yes", 1 + length(continents) + length(regions)  + length(countries)))))
  return(table)
  
  #stargazer(lcont,
  #          se = se.cont,
  #          column.labels = continents,
  #          type = "text", align=TRUE,
  #          omit.stat = c("adj.rsq", "f"))
  #
  #stargazer(lreg,
  #          se = se.reg,
  #          column.labels = regions,
  #          type = "text", align=TRUE,
  #          omit.stat = c("adj.rsq"))
  #
  #
  #stargazer(lcount,
  #          se = se.count,
  #          column.labels = countries,
  #          type = "text", align=TRUE,
  #          omit.stat = c("adj.rsq", "f"))
  #
  
}