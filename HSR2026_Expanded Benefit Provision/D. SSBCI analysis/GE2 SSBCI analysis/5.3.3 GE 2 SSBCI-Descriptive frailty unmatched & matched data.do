cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "5.3.3 GE 2 SSBCI-Descriptive frailty unmatched & matched data 4-9-2026.log", replace
****************************************************************************************
* Purpose: descriptive of unmatched & matched nondual data
* Input file: baseline_matched_SSBCI_nondual_ge2_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_ge2_11match_enrollee_stayer
*             did_anal_stayer
* 4-9-2026 by Ge
****************************************************************************************

* ============ Nondual unmatched ============
    use "did_anal_stayer.dta", clear
    count

    keep if sample_SSBCI==1
    count

    keep if dual_any==0                        
    count

    drop if C_SNP==1
    count
    
    drop if I_SNP==1
    count
    
    keep if curr_elig_incl_esrd != 1
    count

    keep if MA_complete_IP==1
    count

    * first year plan reaches >=2 in post period
    bys contract_plan_id: egen plan_ge2_first_year_SSBCI = min(cond(post_SSBCI==1 & ge2_SSBCI==1, year, .))
    
    * must stay >=2 in all post years from cohort onward
    gen after_ge2_SSBCI = (post_SSBCI==1 & plan_ge2_first_year_SSBCI<. & year>=plan_ge2_first_year_SSBCI)
    
    bys contract_plan_id: egen min_ge2_after_SSBCI = min(cond(after_ge2_SSBCI==1, ge2_SSBCI, .))
    gen plan_ge2_allpost_SSBCI = (plan_ge2_first_year_SSBCI<. & min_ge2_after_SSBCI==1)

    keep if drop_post_SSBCI != 1
    count
    
    drop if trt_SSBCI==1 & trt_plan_has_pre_SSBCI==0
    count
    
    drop if trt_SSBCI==1 & mixed_trt_control_SSBCI==1
    count
    
    drop if trt_SSBCI==0 & mixed_trt_control_SSBCI==1
    count

    drop if trt_SSBCI==1 & stay_same_plan_SSBCI==0
    count

    drop if trt_SSBCI==0 & stay_same_plan_ctrl_SSBCI==0
    count

    keep if any_chronic_condition == 1
    count

    keep if long_term_nh_stayer != 1
    count
    
    global inputs ///
        age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke
    
    foreach var in $inputs {
        drop if `var'==. 
    }
    count

    egen tag_bene = tag(BENE_ID trt_SSBCI)
    tab trt_SSBCI if tag_bene==1

    drop frailty_tertile

isid BENE_ID year
save "enrollee_SSBCI_nondual_ge2_unmatched_stayer.dta", replace


**************************************************************************
* STEP 1. Create frailty baseline unmatched sample
**************************************************************************

clear
set obs 0
gen BENE_ID = .
gen cohort = .
save "FINAL_unmatched_sample_SSBCI_nondual_frailty_ge2.dta", replace

clear
set obs 0
gen BENE_ID = .
save "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta", replace


************************************************
* 2020 adopters -> baseline year 2019
************************************************
use "enrollee_SSBCI_nondual_ge2_unmatched_stayer.dta", clear
keep if year==2019

gen treat = (plan_ge2_first_year_SSBCI==2020 & plan_ge2_allpost_SSBCI==1)
keep if treat==1 | plan_ge2_first_year_SSBCI>2020 | missing(plan_ge2_first_year_SSBCI)

duplicates drop BENE_ID, force

xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

keep if frailty_tertile==1

gen cohort = 2020
save "temp_2020_SSBCI_nondual_frailty_ge2_unmatched.dta", replace

use "FINAL_unmatched_sample_SSBCI_nondual_frailty_ge2.dta", clear
append using "temp_2020_SSBCI_nondual_frailty_ge2_unmatched.dta"
save "FINAL_unmatched_sample_SSBCI_nondual_frailty_ge2.dta", replace

use "temp_2020_SSBCI_nondual_frailty_ge2_unmatched.dta", clear
keep BENE_ID
duplicates drop BENE_ID, force
append using "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta"
save "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta", replace


************************************************
* 2021 adopters -> baseline year 2020
************************************************
use "enrollee_SSBCI_nondual_ge2_unmatched_stayer.dta", clear
keep if year==2020

gen treat = (plan_ge2_first_year_SSBCI==2021 & plan_ge2_allpost_SSBCI==1)
keep if treat==1 | plan_ge2_first_year_SSBCI>2021 | missing(plan_ge2_first_year_SSBCI)

duplicates drop BENE_ID, force

xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

keep if frailty_tertile==1

gen cohort = 2021
save "temp_2021_SSBCI_nondual_frailty_ge2_unmatched.dta", replace

use "FINAL_unmatched_sample_SSBCI_nondual_frailty_ge2.dta", clear
append using "temp_2021_SSBCI_nondual_frailty_ge2_unmatched.dta"
save "FINAL_unmatched_sample_SSBCI_nondual_frailty_ge2.dta", replace

use "temp_2021_SSBCI_nondual_frailty_ge2_unmatched.dta", clear
keep BENE_ID
duplicates drop BENE_ID, force
append using "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta"
save "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta", replace


************************************************
* 2022 adopters -> baseline year 2021
************************************************
use "enrollee_SSBCI_nondual_ge2_unmatched_stayer.dta", clear
keep if year==2021

gen treat = (plan_ge2_first_year_SSBCI==2022 & plan_ge2_allpost_SSBCI==1)
keep if treat==1 | plan_ge2_first_year_SSBCI>2022 | missing(plan_ge2_first_year_SSBCI)

duplicates drop BENE_ID, force

xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

keep if frailty_tertile==1

gen cohort = 2022
save "temp_2022_SSBCI_nondual_frailty_ge2_unmatched.dta", replace

use "FINAL_unmatched_sample_SSBCI_nondual_frailty_ge2.dta", clear
append using "temp_2022_SSBCI_nondual_frailty_ge2_unmatched.dta"
save "FINAL_unmatched_sample_SSBCI_nondual_frailty_ge2.dta", replace

use "temp_2022_SSBCI_nondual_frailty_ge2_unmatched.dta", clear
keep BENE_ID
duplicates drop BENE_ID, force
append using "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta"
save "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta", replace


**************************************************************************
* STEP 2. Clean bene list
**************************************************************************
use "FINAL_unmatched_bene_list_SSBCI_nondual_frailty_ge2.dta", clear
duplicates drop BENE_ID, force
save "FINAL_unmatched_bene_list_CLEAN_SSBCI_nondual_frailty_ge2.dta", replace


**************************************************************************
* STEP 3. Create full unmatched frailty panel
**************************************************************************
use "enrollee_SSBCI_nondual_ge2_unmatched_stayer.dta", clear

merge m:1 BENE_ID using "FINAL_unmatched_bene_list_CLEAN_SSBCI_nondual_frailty_ge2.dta", ///
    keep(match) nogen

replace plan_ge2_first_year_SSBCI = . if ///
    plan_ge2_first_year_SSBCI<. & plan_ge2_allpost_SSBCI!=1

gen treated_ge2_SSBCI  = (plan_ge2_first_year_SSBCI<.)
gen post_ge2_SSBCI     = (year >= plan_ge2_first_year_SSBCI & plan_ge2_first_year_SSBCI<.)
gen trt_post_ge2_SSBCI = treated_ge2_SSBCI * post_ge2_SSBCI

save "baseline_unmatched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer.dta", replace

use "baseline_unmatched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer.dta", clear

local contvars ///
    AGE_AT_END_REF_YR ///
    frailty_score ///
    rbed rmd rsnfbed pct_4year pct_englonly pct_undfpl

local allvars ///
    AGE_AT_END_REF_YR ///
    female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind

display as text "variable                  trt_n        trt_pct      control_n     control_pct"
display as text "----------------------------------------------------------------------------"

foreach v of local allvars {

    local iscont : list v in contvars

    if `iscont' {
        quietly summarize `v' if trt_PHR==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_PHR==0
        local ctrl_n   : display %10.3f r(mean)
        local ctrl_pct : display %10.3f r(sd)

        display as result ///
            %-24s "`v'" ///
            _col(26) "`trt_n'" ///
            _col(39) "`trt_pct'" ///
            _col(53) "`ctrl_n'" ///
            _col(67) "`ctrl_pct'"
    }
    else {
        quietly count if trt_PHR==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_PHR==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_PHR==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_PHR==0 & !missing(`v')
        local ctrl_denom = r(N)
        local ctrl_pct : display %10.4f `ctrl_n'/`ctrl_denom'

        display as result ///
            %-24s "`v'" ///
            _col(26) %10.0f `trt_n' ///
            _col(39) "`trt_pct'" ///
            _col(53) %10.0f `ctrl_n' ///
            _col(67) "`ctrl_pct'"
    }
}

bys trt_SSBCI: sum AGE_AT_END_REF_YR age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    ED_ind IP_ind



* ============ Nondual matched ============
use baseline_matched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer, clear
count

local contvars ///
    AGE_AT_END_REF_YR ///
    frailty_score ///
    rbed rmd rsnfbed pct_4year pct_englonly pct_undfpl

local allvars ///
    AGE_AT_END_REF_YR ///
    female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind

display as text "variable                  trt_n        trt_pct      control_n     control_pct"
display as text "----------------------------------------------------------------------------"

foreach v of local allvars {

    local iscont : list v in contvars

    if `iscont' {
        quietly summarize `v' if trt_PHR==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_PHR==0
        local ctrl_n   : display %10.3f r(mean)
        local ctrl_pct : display %10.3f r(sd)

        display as result ///
            %-24s "`v'" ///
            _col(26) "`trt_n'" ///
            _col(39) "`trt_pct'" ///
            _col(53) "`ctrl_n'" ///
            _col(67) "`ctrl_pct'"
    }
    else {
        quietly count if trt_PHR==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_PHR==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_PHR==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_PHR==0 & !missing(`v')
        local ctrl_denom = r(N)
        local ctrl_pct : display %10.4f `ctrl_n'/`ctrl_denom'

        display as result ///
            %-24s "`v'" ///
            _col(26) %10.0f `trt_n' ///
            _col(39) "`trt_pct'" ///
            _col(53) %10.0f `ctrl_n' ///
            _col(67) "`ctrl_pct'"
    }
}

bys trt_SSBCI: sum AGE_AT_END_REF_YR age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    ED_ind IP_ind



* ============ Dual unmatched ============
    use "did_anal_stayer.dta", clear
    count

    keep if sample_SSBCI==1
    count

    keep if dual_any==1                       
    count

    drop if C_SNP==1
    count
    
    drop if I_SNP==1
    count
    
    keep if curr_elig_incl_esrd != 1
    count

    keep if MA_complete_IP==1
    count

    * first year plan reaches >=2 in post period
    bys contract_plan_id: egen plan_ge2_first_year_SSBCI = min(cond(post_SSBCI==1 & ge2_SSBCI==1, year, .))
    
    * must stay >=2 in all post years from cohort onward
    gen after_ge2_SSBCI = (post_SSBCI==1 & plan_ge2_first_year_SSBCI<. & year>=plan_ge2_first_year_SSBCI)
    
    bys contract_plan_id: egen min_ge2_after_SSBCI = min(cond(after_ge2_SSBCI==1, ge2_SSBCI, .))
    gen plan_ge2_allpost_SSBCI = (plan_ge2_first_year_SSBCI<. & min_ge2_after_SSBCI==1)

    keep if drop_post_SSBCI != 1
    count
    
    drop if trt_SSBCI==1 & trt_plan_has_pre_SSBCI==0
    count
    
    drop if trt_SSBCI==1 & mixed_trt_control_SSBCI==1
    count
    
    drop if trt_SSBCI==0 & mixed_trt_control_SSBCI==1
    count

    drop if trt_SSBCI==1 & stay_same_plan_SSBCI==0
    count

    drop if trt_SSBCI==0 & stay_same_plan_ctrl_SSBCI==0
    count

    keep if any_chronic_condition == 1
    count

    keep if long_term_nh_stayer != 1
    count
    
    global inputs ///
        age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke
    
    foreach var in $inputs {
        drop if `var'==. 
    }
    count

    egen tag_bene = tag(BENE_ID trt_SSBCI)
    tab trt_SSBCI if tag_bene==1

    drop frailty_tertile

isid BENE_ID year
save "enrollee_SSBCI_dual_ge2_unmatched_stayer.dta", replace


**************************************************************************
* STEP 1. Create frailty baseline unmatched sample
**************************************************************************

clear
set obs 0
gen BENE_ID = .
gen cohort = .
save "FINAL_unmatched_sample_SSBCI_dual_frailty_ge2.dta", replace

clear
set obs 0
gen BENE_ID = .
save "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta", replace


************************************************
* 2020 adopters -> baseline year 2019
************************************************
use "enrollee_SSBCI_dual_ge2_unmatched_stayer.dta", clear
keep if year==2019

gen treat = (plan_ge2_first_year_SSBCI==2020 & plan_ge2_allpost_SSBCI==1)
keep if treat==1 | plan_ge2_first_year_SSBCI>2020 | missing(plan_ge2_first_year_SSBCI)

duplicates drop BENE_ID, force

xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

keep if frailty_tertile==1

gen cohort = 2020
save "temp_2020_SSBCI_dual_frailty_ge2_unmatched.dta", replace

use "FINAL_unmatched_sample_SSBCI_dual_frailty_ge2.dta", clear
append using "temp_2020_SSBCI_dual_frailty_ge2_unmatched.dta"
save "FINAL_unmatched_sample_SSBCI_dual_frailty_ge2.dta", replace

use "temp_2020_SSBCI_dual_frailty_ge2_unmatched.dta", clear
keep BENE_ID
duplicates drop BENE_ID, force
append using "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta"
save "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta", replace


************************************************
* 2021 adopters -> baseline year 2020
************************************************
use "enrollee_SSBCI_dual_ge2_unmatched_stayer.dta", clear
keep if year==2020

gen treat = (plan_ge2_first_year_SSBCI==2021 & plan_ge2_allpost_SSBCI==1)
keep if treat==1 | plan_ge2_first_year_SSBCI>2021 | missing(plan_ge2_first_year_SSBCI)

duplicates drop BENE_ID, force

xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

keep if frailty_tertile==1

gen cohort = 2021
save "temp_2021_SSBCI_dual_frailty_ge2_unmatched.dta", replace

use "FINAL_unmatched_sample_SSBCI_dual_frailty_ge2.dta", clear
append using "temp_2021_SSBCI_dual_frailty_ge2_unmatched.dta"
save "FINAL_unmatched_sample_SSBCI_dual_frailty_ge2.dta", replace

use "temp_2021_SSBCI_dual_frailty_ge2_unmatched.dta", clear
keep BENE_ID
duplicates drop BENE_ID, force
append using "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta"
save "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta", replace


************************************************
* 2022 adopters -> baseline year 2021
************************************************
use "enrollee_SSBCI_dual_ge2_unmatched_stayer.dta", clear
keep if year==2021

gen treat = (plan_ge2_first_year_SSBCI==2022 & plan_ge2_allpost_SSBCI==1)
keep if treat==1 | plan_ge2_first_year_SSBCI>2022 | missing(plan_ge2_first_year_SSBCI)

duplicates drop BENE_ID, force

xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

keep if frailty_tertile==1

gen cohort = 2022
save "temp_2022_SSBCI_dual_frailty_ge2_unmatched.dta", replace

use "FINAL_unmatched_sample_SSBCI_dual_frailty_ge2.dta", clear
append using "temp_2022_SSBCI_dual_frailty_ge2_unmatched.dta"
save "FINAL_unmatched_sample_SSBCI_dual_frailty_ge2.dta", replace

use "temp_2022_SSBCI_dual_frailty_ge2_unmatched.dta", clear
keep BENE_ID
duplicates drop BENE_ID, force
append using "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta"
save "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta", replace


**************************************************************************
* STEP 2. Clean bene list
**************************************************************************
use "FINAL_unmatched_bene_list_SSBCI_dual_frailty_ge2.dta", clear
duplicates drop BENE_ID, force
save "FINAL_unmatched_bene_list_CLEAN_SSBCI_dual_frailty_ge2.dta", replace


**************************************************************************
* STEP 3. Create full unmatched frailty panel
**************************************************************************
use "enrollee_SSBCI_dual_ge2_unmatched_stayer.dta", clear

merge m:1 BENE_ID using "FINAL_unmatched_bene_list_CLEAN_SSBCI_dual_frailty_ge2.dta", ///
    keep(match) nogen

replace plan_ge2_first_year_SSBCI = . if ///
    plan_ge2_first_year_SSBCI<. & plan_ge2_allpost_SSBCI!=1

gen treated_ge2_SSBCI  = (plan_ge2_first_year_SSBCI<.)
gen post_ge2_SSBCI     = (year >= plan_ge2_first_year_SSBCI & plan_ge2_first_year_SSBCI<.)
gen trt_post_ge2_SSBCI = treated_ge2_SSBCI * post_ge2_SSBCI

save "baseline_unmatched_SSBCI_dual_frailty_ge2_11match_enrollee_stayer.dta", replace

use "baseline_unmatched_SSBCI_dual_frailty_ge2_11match_enrollee_stayer.dta", clear


local contvars ///
    AGE_AT_END_REF_YR ///
    frailty_score ///
    rbed rmd rsnfbed pct_4year pct_englonly pct_undfpl

local allvars ///
    AGE_AT_END_REF_YR ///
    female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    CO FIDE_HIDE ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind

display as text "variable                  trt_n        trt_pct      control_n     control_pct"
display as text "----------------------------------------------------------------------------"

foreach v of local allvars {

    local iscont : list v in contvars

    if `iscont' {
        quietly summarize `v' if trt_PHR==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_PHR==0
        local ctrl_n   : display %10.3f r(mean)
        local ctrl_pct : display %10.3f r(sd)

        display as result ///
            %-24s "`v'" ///
            _col(26) "`trt_n'" ///
            _col(39) "`trt_pct'" ///
            _col(53) "`ctrl_n'" ///
            _col(67) "`ctrl_pct'"
    }
    else {
        quietly count if trt_PHR==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_PHR==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_PHR==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_PHR==0 & !missing(`v')
        local ctrl_denom = r(N)
        local ctrl_pct : display %10.4f `ctrl_n'/`ctrl_denom'

        display as result ///
            %-24s "`v'" ///
            _col(26) %10.0f `trt_n' ///
            _col(39) "`trt_pct'" ///
            _col(53) %10.0f `ctrl_n' ///
            _col(67) "`ctrl_pct'"
    }
}

bys trt_SSBCI: sum AGE_AT_END_REF_YR age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    CO FIDE_HIDE ///
    ED_ind IP_ind


* ============ Dual matched ============
use baseline_matched_SSBCI_dual_frailty_ge2_11match_enrollee_stayer, clear
count

local contvars ///
    AGE_AT_END_REF_YR ///
    frailty_score ///
    rbed rmd rsnfbed pct_4year pct_englonly pct_undfpl

local allvars ///
    AGE_AT_END_REF_YR ///
    female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    CO FIDE_HIDE ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind

display as text "variable                  trt_n        trt_pct      control_n     control_pct"
display as text "----------------------------------------------------------------------------"

foreach v of local allvars {

    local iscont : list v in contvars

    if `iscont' {
        quietly summarize `v' if trt_PHR==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_PHR==0
        local ctrl_n   : display %10.3f r(mean)
        local ctrl_pct : display %10.3f r(sd)

        display as result ///
            %-24s "`v'" ///
            _col(26) "`trt_n'" ///
            _col(39) "`trt_pct'" ///
            _col(53) "`ctrl_n'" ///
            _col(67) "`ctrl_pct'"
    }
    else {
        quietly count if trt_PHR==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_PHR==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_PHR==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_PHR==0 & !missing(`v')
        local ctrl_denom = r(N)
        local ctrl_pct : display %10.4f `ctrl_n'/`ctrl_denom'

        display as result ///
            %-24s "`v'" ///
            _col(26) %10.0f `trt_n' ///
            _col(39) "`trt_pct'" ///
            _col(53) %10.0f `ctrl_n' ///
            _col(67) "`ctrl_pct'"
    }
}

bys trt_SSBCI: sum AGE_AT_END_REF_YR age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    CO FIDE_HIDE ///
    ED_ind IP_ind






log close

