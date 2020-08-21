
********** General code structure  ************************

eststo [name of column 1]: [regression command]
estadd local [name of extra row 1] [content of extra row]
esttab [name of column 1] [name of column 2] using [file path],  nonumbers se label star(* 0.10 ** 0.05 *** 0.01) /*
*/ keep([Regressor of interest]) mtitles([Names displayed of columns]) mgroups([Title of column], pattern(1 0) /* 
[Patter says what columns to apply the title to. For example if you have 4 columns, want first twoo to have one title and the second two another
you write mttiles("Title 1" "Title 2"), pattern(1 0 1 0)] If you want the first title to apply to the first three columns you write pattern(1 0 0 1)]
*/ prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )  /* This is some code to format the table
*/ scalars("[Name of extra row 1] [Title of row 1]" "[Name of extra row 1] [Title of row 1]" )  compress replace 


* If you want to include the tests as extra rows you just have to find were they are stored.
* Example of how you can add the mean of a variable

sum var1
estadd scalar Mean = r(mean)
Then in the esttab command option scalars you add ("Mean Mean of Variable 1")

********** Example from my code  ************************

* Probability of being above median, state FE
eststo a_tb1: reghdfe above_medinc_c i.center i.ever_treated 1.ever_treated#1.treatment_80s i.center#i.ever_treated  ddd  if cohort <1990, abs(i.statefips  i.year)
estadd local extra_row1 "Yes"
estadd local extra_row2 "Yes"
estadd local extra_row3 "No"
estadd local extra_row4 "No"
estadd local extra_row5 "No"

*City FE
eststo b_tb1: reghdfe above_medinc_c i.center i.ever_treated 1.ever_treated#1.treatment_80s i.center#i.ever_treated ddd  if cohort <1990, abs(i.statefips i.cbsa i.year)
estadd local extra_row1 "Yes"
estadd local extra_row2 "Yes"
estadd local extra_row3 "Yes"
estadd local extra_row4 "No"
estadd local extra_row5 "No"

*City FE, State time trends
eststo c_tb1: reghdfe above_medinc_c i.center i.ever_treated 1.ever_treated#1.treatment_80s i.center#i.ever_treated ddd c.year#i.statefips if cohort <1990, abs(i.statefips i.cbsa i.year)
estadd local extra_row1 "Yes"
estadd local extra_row2 "Yes"
estadd local extra_row3 "Yes"
estadd local extra_row4 "Yes"
estadd local extra_row5 "No"

 *City FE, State time trends and log city size
eststo d_tb1: reghdfe above_medinc_c i.center i.ever_treated 1.ever_treated#1.treatment_80s i.center#i.ever_treated ddd lpop_msa c.year#i.statefips if cohort <1990, abs(i.statefips i.cbsa i.year)
estadd local extra_row1 "Yes"
estadd local extra_row2 "Yes"
estadd local extra_row3 "Yes"
estadd local extra_row4 "Yes"
estadd local extra_row5 "Yes"
 
esttab a_tb1 b_tb1 c_tb1 d_tb1 using "$tables/Gentrification_clara/prob_above_median.tex",  nonumbers se label star(* 0.10 ** 0.05 *** 0.01) /*
*/ keep(ddd) mtitles("(1)" "(2)" "(3)" "(4)") mgroups("Probability of being above median income" , pattern(1 0) /*
*/ prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) )  /*
*/ scalars("extra_row1 Year FE" "extra_row2 State FE" "extra_row3 CBSA FE" "extra_row4 State time trends" "extra_row5 Log CBSA population")  compress replace 
