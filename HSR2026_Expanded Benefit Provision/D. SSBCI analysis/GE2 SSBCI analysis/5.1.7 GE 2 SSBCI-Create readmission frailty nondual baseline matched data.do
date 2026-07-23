cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "5.1.7 GE 2 SSBCI-Create readmission frailty nondual baseline matched data 3-18-2026.log", replace
****************************************************************************************
* Purpose: To create baseline ps matching data for SSBCI and nondual only:
*          1-1 matching over the entire pre-period at enrollee level.
*          Matching use caliper with 10% of SD ps score and 1-1 nearest neighbor
* Input file: did_stayer_readm
* Output file: baseline_matched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer_readm
* 3-18-2026 by Ge
****************************************************************************************


    use "did_stayer_readm.dta", clear
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

    save "enrollee_SSBCI_nondual_frailty_ge2_11match_stayer_readm.dta", replace
    count


* Empty files for final results
clear
gen BENE_ID = .
save "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", replace emptyok
save "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta", replace emptyok   // only IDs, for later merge

********************************************************************************
* 2020 ADOPTERS - baseline year = 2019
********************************************************************************
use "enrollee_SSBCI_nondual_frailty_ge2_11match_stayer_readm.dta", clear
keep if year == 2019
gen treat = (plan_ge2_first_year_SSBCI == 2020 & plan_ge2_allpost_SSBCI == 1)
keep if treat==1 | plan_ge2_first_year_SSBCI > 2020 | missing(plan_ge2_first_year_SSBCI)
duplicates drop BENE_ID, force
tab treat

* define frailty tertile from baseline frailty score
xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

label define frailty3 1 "High frailty" 2 "Middle frailty" 3 "Low frailty"
label values frailty_tertile frailty3

* keep only high frailty subgroup
keep if frailty_tertile == 1
count
tab treat
tab frailty_tertile

* Estimate propensity score
logit treat age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

predict pscore if e(sample), pr
sum pscore if e(sample)
local caliper = 0.1 * r(sd)

display "Caliper = " `caliper'

* matching use 1:1 nearest neighbor + caliper
psmatch2 treat, pscore(pscore) neighbor(1) caliper(`caliper') common noreplacement

keep if !missing(_weight) & _weight>0
tab treat

gen cohort = 2020
save "temp_2020_SSBCI_nondual_frailty_ge2_readm.dta", replace

* Append to master files
use "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", clear
append using "temp_2020_SSBCI_nondual_frailty_ge2_readm.dta"
save "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", replace

use "temp_2020_SSBCI_nondual_frailty_ge2_readm.dta", clear
keep BENE_ID
duplicates drop
append using "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta"
save "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta", replace

********************************************************************************
* 2021 ADOPTERS - baseline year = 2020
********************************************************************************
use "enrollee_SSBCI_nondual_frailty_ge2_11match_stayer_readm.dta", clear
keep if year == 2020
gen treat = (plan_ge2_first_year_SSBCI == 2021 & plan_ge2_allpost_SSBCI == 1)
keep if treat==1 | plan_ge2_first_year_SSBCI > 2021 | missing(plan_ge2_first_year_SSBCI)
duplicates drop BENE_ID, force

tab treat

* define frailty tertile from baseline frailty score
xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

label define frailty3 1 "High frailty" 2 "Middle frailty" 3 "Low frailty"
label values frailty_tertile frailty3

* keep only high frailty subgroup
keep if frailty_tertile == 1
count
tab treat
tab frailty_tertile

* Estimate propensity score
logit treat age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

predict pscore if e(sample), pr
sum pscore if e(sample)
local caliper = 0.1 * r(sd)

display "Caliper = " `caliper'

* matching use 1:1 nearest neighbor + caliper
psmatch2 treat, pscore(pscore) neighbor(1) caliper(`caliper') common noreplacement

keep if !missing(_weight) & _weight>0
tab treat

gen cohort = 2021
save "temp_2021_SSBCI_nondual_frailty_ge2_readm.dta", replace

use "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", clear
append using "temp_2021_SSBCI_nondual_frailty_ge2_readm.dta"
save "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", replace

use "temp_2021_SSBCI_nondual_frailty_ge2_readm.dta", clear
keep BENE_ID
duplicates drop
append using "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta"
save "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta", replace

********************************************************************************
* 2022 ADOPTERS - baseline year = 2021
********************************************************************************
use "enrollee_SSBCI_nondual_frailty_ge2_11match_stayer_readm.dta", clear
keep if year == 2021
gen treat = (plan_ge2_first_year_SSBCI == 2022 & plan_ge2_allpost_SSBCI == 1)
keep if treat==1 | plan_ge2_first_year_SSBCI > 2022 | missing(plan_ge2_first_year_SSBCI)
duplicates drop BENE_ID, force

tab treat

* define frailty tertile from baseline frailty score
xtile frailty_tertile0 = frailty_score, n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

label define frailty3 1 "High frailty" 2 "Middle frailty" 3 "Low frailty"
label values frailty_tertile frailty3

* keep only high frailty subgroup
keep if frailty_tertile == 1
count
tab treat
tab frailty_tertile

* Estimate propensity score
logit treat age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

predict pscore if e(sample), pr
sum pscore if e(sample)
local caliper = 0.1 * r(sd)

display "Caliper = " `caliper'

* matching use 1:1 nearest neighbor + caliper
psmatch2 treat, pscore(pscore) neighbor(1) caliper(`caliper') common noreplacement

keep if !missing(_weight) & _weight>0
tab treat

gen cohort = 2022
save "temp_2022_SSBCI_nondual_frailty_ge2_readm.dta", replace

use "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", clear
append using "temp_2022_SSBCI_nondual_frailty_ge2_readm.dta"
save "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", replace

use "temp_2022_SSBCI_nondual_frailty_ge2_readm.dta", clear
keep BENE_ID
duplicates drop
append using "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta"
save "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta", replace

* Clean up temporary files
erase temp_2020_SSBCI_nondual_frailty_ge2_readm.dta
erase temp_2021_SSBCI_nondual_frailty_ge2_readm.dta
erase temp_2022_SSBCI_nondual_frailty_ge2_readm.dta

********************************************************************************
* FINAL STEP 1: Matched sample (one row per person in baseline year) → for balance table
********************************************************************************
use "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", clear
save "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", replace

tab treat
tab cohort treat


********************************************************************************
* FINAL STEP 2: Create the full analysis panel (all years, all outcomes)
********************************************************************************
use "FINAL_matched_bene_list_SSBCI_nondual_frailty_ge2_readm.dta", clear
duplicates report BENE_ID
duplicates drop BENE_ID, force
save "FINAL_matched_bene_list_CLEAN_SSBCI_nondual_frailty_ge2_readm.dta", replace

use "enrollee_SSBCI_nondual_frailty_ge2_11match_stayer_readm.dta", clear

* Keep ONLY the matched beneficiaries (treated + their controls)
merge m:1 BENE_ID using "FINAL_matched_bene_list_CLEAN_SSBCI_nondual_frailty_ge2_readm.dta", keep(match) nogen

* treated plans must satisfy plan_ge2_allpost_SSBCI==1
replace plan_ge2_first_year_SSBCI = . if plan_ge2_first_year_SSBCI < . & ///
    plan_ge2_allpost_SSBCI != 1

* GE2 treatment indicators for DiD / event study
gen treated_ge2_SSBCI = (plan_ge2_first_year_SSBCI < .)
gen post_ge2_SSBCI = (year >= plan_ge2_first_year_SSBCI & plan_ge2_first_year_SSBCI < .)
gen trt_post_ge2_SSBCI  = treated_ge2_SSBCI * post_ge2_SSBCI

save "baseline_matched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer_readm.dta", replace
count
tab treated


* Check distribution
    use "FINAL_matched_sample_SSBCI_nondual_frailty_ge2_readm.dta", clear 

    bys treat: sum /// 
        age_64 age_6569 age_7074 age_7579 age_8084 age_85 female /// 
        white black hispanic asian other_race /// 
        frailty_score rbed rmd rsnfbed /// 
        pct_4year pct_englonly pct_undfpl rural /// 
        Transportation Meal /// 
        AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage /// 
        ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers /// 
        oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke /// 
        readm_ind




log close

