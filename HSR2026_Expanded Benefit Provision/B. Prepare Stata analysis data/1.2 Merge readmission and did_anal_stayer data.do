cd "/home/gso275/files/dua_&dua./Stata/Benefit_ITT_Revise"
capture log close
log using "1.2 Merge readmission and did_anal_stayer data 3-16-2026.log", replace
****************************************************************************************
* Purpose: Merge readmission and did_anal data.
* Input file: readm
*             did_anal_stayer
* Output file: did_readm
****************************************************************************************

use "/home/gso275/files/dua_&dua./Stata/Benefit_ITT/readm", clear
count
keep BENE_ID year readm_ind

merge 1:1 BENE_ID year using did_anal_stayer
keep if _merge==3
drop _merge
count

compress
save did_stayer_readm, replace
count




log close