clear all

import delimited /Users/rodrigo/Documents/tfg/data/models/datamdodels_dummies.csv
gen logprod = log(prod_area)
xtset idx year

// fixed effects regression
xtreg logprod compactness ,fe robust

gen compactindia = compactness*country_india 
gen compactafrica =compactness*contnnt_africa 
gen compactasia =compactness*contnnt_asia 

gen pot_compactafrica = pot_compactness*contnnt_africa 
gen pot_compactasia   = pot_compactness*contnnt_asia 
gen pot_compactindia  = pot_compactness*country_india 

// IV estimation

keep if country == "India"
xtivreg2 logprod (compactness = pot_compactness), fe robust
// Africa
xtivreg2 logprod (compactafrica = pot_compactafrica), fe robust

// Asia
xtivreg2 logprod (compactasia = pot_compactasia), fe robust

// India
xtivreg2 logprod (compactindia = pot_compactindia), fe robust
