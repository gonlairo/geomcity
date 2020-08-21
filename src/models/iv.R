iv = function(df, formula, continents, regions, countries){
  
  iv_fe_world <- plm(formula,
                     data = df,
                     effect = c('twoways'),
                     index = c('id', 'year'),
                     inst.method = "bvk")
  
  # CONTINENTS
  lcont = vector("list")
  for (cont in continents) {
    data = df %>% filter(continent == cont)
    ivfe = plm(formula,
               data = data,
               effect = c('twoways'),
               index = c('id', 'year'),
               model = "within")
    
    lcont[[cont]] = ivfe
  }
  
  # REGIONS
  lreg = vector("list")
  for (reg in regions) {
    data = df %>% filter(region == reg)
    ivfe = plm(formula,
               data = data,
               effect = c('twoways'),
               index = c('id', 'year'),
               model = "within")
    lreg[[reg]] = ivfe
  }
  
  # COUNTRIES
  lcount = vector("list")
  for (count in countries) {
    
    data = df %>% filter(country == count)
    ivfe = plm(formula,
               data = data,
               effect = c('twoways'),
               index = c('id', 'year'),
               model = "within")
    
    lcount[[count]] = ivfe
  }
  
  #table
  table = stargazer(iv_fe_world, lcont, lreg,lcount,
            column.labels = c("ALL", continents, regions, countries),
            type = "text", align=TRUE,
            omit.stat = c("adj.rsq", "f"), df = FALSE,
            add.lines = list(c('City FE', rep("Yes", 1 + length(continents) + length(regions) + length(countries))),
                             c('Time FE', rep("Yes", 1 + length(continents) + length(regions)  + length(countries)))))
  
  return(table)
}

