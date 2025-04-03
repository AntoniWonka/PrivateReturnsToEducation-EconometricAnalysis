//filter data
keep if STATE == "Michigan"
keep if A_AGE >= 18 & A_AGE <= 64
gen degree = A_HGA


recode degree (0 31 32 33=0) 
recode degree (34 35 36 37 38=1) 
recode degree (39 40=2)
recode degree (41 42 43=3)
recode degree (44 45 46=4) 

// Degree categorical variable

label define degree_lbl 0 "Less than 7-8 years" ///
                       1 "7-12 years, no high school diploma" ///
                       2 "High school diploma or some college, no degree" ///
                       3 "Associate or Bachelor degrees" ///
                       4 "Master's degree or above"


label variable degree "Highest Degree Attained"


// data investigation to justify filtering out salary == 0

tabulate PEIO1COW if WSAL_VAL == 0

tabulate HRSWK if PEIO1COW == 4 & WSAL_VAL == 0

tabulate PEIO1COW if WSAL_VAL == 0 & HRSWK == 0

tabulate HRSWK if WSAL_VAL == 0 & PEIO1COW == 7

drop if WSAL_VAL == 0

correlate

tab PRDTRACE

//2. descriptives

summarize WSAL_VAL   // Summary statistics for wages

gen ln_wage = log(WSAL_VAL) if WSAL_VAL > 0 // generating log
summarize ln_wage 

// comparing before and after log transformation
histogram WSAL_VAL, bin(50) percent title("Wage Distribution (Original)") xlabel(,angle(45))
histogram ln_wage, bin(50) percent title("Log(Wage) Distribution") xlabel(,angle(45))
graph box WSAL_VAL, over(degree) title("Wage Distribution by Education Level")
graph box ln_wage, over(degree) title("Log(Wage) Distribution by Education Level")
graph save "Graph" "/Users/marko/Desktop/log wage by educ level.gph"
graph box WSAL_VAL, over(degree) title("Wage Distribution by Education Level")
graph save "Graph" "/Users/marko/Desktop/wage by educ level box plot.gph"

tab degree, summarize(WSAL_VAL)
tab degree, summarize(ln_wage)
summarize(WSAL_VAL)



//3. first regression

gen age_squared = A_AGE * A_AGE

reg ln_wage degree A_AGE age_squared

reg ln_wage i.degree A_AGE age_squared, robust
reg ln_wage ib2.degree A_AGE age_squared, robust


// check for homocedastic
reg ln_wage degree A_AGE age_squared 
estat hettest
imtest, white

predict resid, residuals

scatter resid A_AGE, msize(small) title("Residuals vs. Age")
scatter resid degree, msize(small) title("Residuals vs. Education Level")



// regression with sex added

gen female = (A_SEX == 2)

reg ln_wage degree A_AGE age_squared female, robust

// regression with sex and age interaction

reg ln_wage c.degree##female A_AGE age_squared, robust

reg ln_wage c.degree##female c.A_AGE##female age_squared, robust

reg ln_wage c.degree##female A_AGE age_squared, robust



************************************************************
* 1) Generate Additional Variables for Augmented Model
************************************************************

* A) Female dummy: 1 if female, 0 if male
gen female = (A_SEX == 2) if !missing(A_SEX)
label variable female "Female=1, Male=0"

* B) Race dummy: 1 if White only, else 0
gen white = (PRDTRACE == 1) if !missing(PRDTRACE)
label variable white "White=1, Non-White=0"
reg ln_wage degree A_AGE age_squared female white, robust

* C) Marital Status: 
*   1=Marr-civ sp present, 2=Marr-AF spo present 
gen married = (A_MARITL == 1 | A_MARITL == 2) if !missing(A_MARITL)
label variable married "Married=1 if spouse present"

* D) Health remains numeric (1=Excellent .. 5=Poor), no recode needed
*    but you can label it if you wish:
* label variable HEA "Health status (1=Excellent, 5=Poor)"

* E) Hours worked squared
gen hrswk_sq = HRSWK^2 if HRSWK < .
label variable hrswk_sq "Squared hours worked per week"

************************************************************
* 2) Final Augmented Regression
************************************************************

reg ln_wage degree A_AGE age_squared female white married HEA HRSWK hrswk_sq, robust

* Explanation:
*  - 'degree' : Categorical education variable (0–4) 
*  - 'A_AGE' & 'age_squared' : Age (experience proxy)
*  - 'female' : Gender dummy (1=Female)
*  - 'white'  : Race dummy (1=White)
*  - 'married': Marital status dummy
*  - 'HEA'    : Health index
*  - 'HRSWK'  : Hours worked per week
*  - 'hrswk_sq': Hours worked squared
*  - robust
************************************************************



