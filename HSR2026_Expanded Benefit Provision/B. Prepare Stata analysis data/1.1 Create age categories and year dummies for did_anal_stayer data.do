cd "/home/gso275/files/dua_&dua./Stata/Benefit_ITT_Revise"
capture log close
log using "1.1 Create age categories and year dummies for did_anal_stayer data 3-16-2025.log", replace
****************************************************************************************
* Purpose: Create category indicators of age and year dummies;
* Input file: did_anal_stayer
* Output file: did_anal_stayer
****************************************************************************************

use did_anal_stayer, clear
count 

* construct indicators of age category
** <= 64 ref
** [65, 69]
** [70, 74]
** [75, 79]
** [80, 84]
** >= 85
    
gen age_64=0
replace age_64 = 1 if AGE_AT_END_REF_YR < 65
    
gen age_6569=0
replace age_6569 = 1 if AGE_AT_END_REF_YR >= 65 & AGE_AT_END_REF_YR < 70
    
gen age_7074=0
replace age_7074 = 1 if AGE_AT_END_REF_YR >= 70 & AGE_AT_END_REF_YR < 75
    
gen age_7579=0
replace age_7579 = 1 if AGE_AT_END_REF_YR >= 75 & AGE_AT_END_REF_YR < 80
    
gen age_8084=0
replace age_8084 = 1 if AGE_AT_END_REF_YR >= 80 & AGE_AT_END_REF_YR < 85
    
gen age_85=0
replace age_85 = 1 if AGE_AT_END_REF_YR >= 85
    
* add year dummies
tab year
gen year2022=0 
replace year2022=1 if year==2022
    
gen year2021=0 
replace year2021=1 if year==2021

gen year2020=0 
replace year2020=1 if year==2020
    
gen year2019=0 
replace year2019=1 if year==2019
    
gen year2018=0 
replace year2018=1 if year==2018
    
gen year2017=0 
replace year2017=1 if year==2017

gen FIDE_HIDE=.
replace FIDE_HIDE=0 if D_SNP==1
replace FIDE_HIDE=1 if FIDE==1 | HIDE==1

compress
count
    
save did_anal_stayer, replace


log close
