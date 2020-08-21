/******************************************************************************

* Title: models_tfg.do
* Created by: Rodrigo Gonzalez Laiz
* Dataset: df_final.csv
* Purpose: IVFE, IVQR
* Created on: 15/06/2020

******************************************************************************/

log close _all
clear all

// import data
import delimited /Users/rodrigo/Documents/tfg/data/final/df_final_noNAF.csv

// create necessary variables
gen logprod = log(productivity)
gen logcohesion = log(cohesion)
gen logproximity = log(proximity)
gen logspin = log(spin)


// set panel
xtset id year

************************************************
************************************************

// Fixed effects estimation //

// ALL: negative and significant
xtreg logprod cohesion i.year, fe robust

// Africa: negative and significant
preserve
keep if continent == "Africa"
xtreg logprod cohesion i.year, fe robust cluster(id)
restore

// Subsaharan Africa: negative and significant 
preserve
keep if continent == "Africa" & region != "NAF"
xtreg logprod cohesion i.year, fe robust
restore

// Asia: positive and significant
preserve
keep if continent == "Asia"
xtreg logprod cohesion i.year, fe robust
restore

// China: positive and significant
preserve
keep if country == "China"
xtreg logprod cohesion i.year, fe robust
restore

// India: positive and significant
preserve
keep if country == "India"
xtreg logprod cohesion i.year, fe robust
restore

sysuse auto
eststo clear
eststo: xtreg weight length turn , fe i(rep78)
estadd local fixed "yes" , replace
eststo: xtreg weight length turn , re i(rep78)
estadd local fixed "no" , replace
esttab , cells(b) indicate(turn) s(fixed N, label("fixed effects"))


************************************************
************************************************

// Instrumental variables estimation //

// ALL: negative and significant
xi: xtivreg2 logprod (compactness = pcompactness) i.year,  fe robust


// Africa: negative and significant
preserve
keep if continent == "Africa"
xi: xtivreg2 logprod (cohesion = pcohesion) i.year,  fe robust
restore

// Subsaharan Africa: negative and significant
preserve
keep if continent == "Africa" & region != "NAF"
xi: xtivreg2 logprod (cohesion = pcohesion) i.year, first fe robust
restore

// Asia: positive and significant
preserve
keep if continent == "Asia"
xi: xtivreg2 logprod (cohesion = pcohesion) i.year, fe robust
restore

// China: positive and significant
preserve
keep if country == "China"
xi: xtivreg2 logprod (cohesion = pcohesion) i.year, first fe robust
restore

// India: positive and significant
preserve
keep if country == "India"
xi: xtivreg2 logprod (compactness = pcompactness) i.year, fe robust
restore


twostepweakiv 2sls logprod (cohesion = pcohesion)

************************************************
************************************************

// Fixed Effects quantile regression


// ALL: negative and significant
xtqreg logprod cohesion i.year, i(id) quantile( .05 .1(0.1)0.9 .95)

// Africa: UPWARD
preserve
keep if continent == "Africa"
xtqreg logprod cohesion i.year, i(id) quantile( .05 .1(0.1)0.9 .95)
restore

// Subsaharan Africa: UPWARD A LOT, neither quantile significant 
preserve
keep if continent == "Africa" & region != "NAF"
xtqreg logprod cohesion i.year, i(id) quantile( .05 .1(0.1)0.9 .95)
restore

// Asia: UPWARD, first quantiles not significant
preserve
keep if continent == "Asia"
xtqreg logprod cohesion i.year, i(id) quantile( .05 .1(0.1)0.9 .95)
restore

// China: CONSTANT
preserve
keep if country == "China"
xtqreg logprod cohesion i.year, i(id) quantile( .05 .1(0.1)0.9 .95)
restore

// India: DOWNWARD
preserve
keep if country == "India" & year == 2009

xtqreg logprod cohesion i.year, i(id) quantile( .05 .1(0.1)0.9 .95)
ivqreg2 logprod compactness, inst(pcompactness) q(0.15 .25 .5 .75 .85)
restore



// long differences
clear all
import delimited /Users/rodrigo/Documents/tfg/data/final/df_india_ld.csv

// create necessary variables
gen logprod = log(productivity)

// normal regression long differences
reg logprod compactness, robust

// quantile regression
sqreg logprod compactness, q(.01 .1 .25 .5 .75 .9 .95)

//ivqreg2 logprod compactness i.year, i(id) quantile( .05 .1(0.1)0.9 .95)
ivqreg2 logprod compactness, inst(pcompactness) q(0.15 .25 .5 .75 .85)




clear all
import delimited /Users/rodrigo/Documents/tfg/data/final/df_china_ld.csv
// create necessary variables
gen logprod = log(productivity)

// normal regression long differences
reg logprod compactness, robust

// quantile regression
sqreg logprod compactness, q(.01 .1 .25 .5 .75 .9 .95)

//ivqreg2 logprod compactness i.year, i(id) quantile( .05 .1(0.1)0.9 .95)
ivqreg2 logprod compactness, inst(pcompactness) q(0.15 .25 .5 .75 .85)


