cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "4.1.6 GE 2 PHR-Create readmission dual baseline matched data 3-18-2026.log", replace
****************************************************************************************
* Purpose: To create baseline ps matching data for PHR dual only with restriction:
*          matching over the entire pre-period.
*          Matching use caliper with 10% of SD ps score and 1-1 nearest neighbor
* Input file: did_stayer_readm
* Output file: baseline_matched_PHR_dual_ge2_11match_enrollee_stayer_readm
* 3-18-2026 by Ge
****************************************************************************************


use "did_stayer_readm.dta", clear
count

keep if sample_PHR==1
count

keep if dual_any == 1
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
bys contract_plan_id: egen plan_ge2_first_year_PHR = min(cond(post_PHR==1 & ge2_PHR==1, year, .))

* must stay >=2 in all post years from cohort onward
gen after_ge2_PHR = (post_PHR==1 & plan_ge2_first_year_PHR<. & year>=plan_ge2_first_year_PHR)

bys contract_plan_id: egen min_ge2_after_PHR = min(cond(after_ge2_PHR==1, ge2_PHR, .))
gen plan_ge2_allpost_PHR = (plan_ge2_first_year_PHR<. & min_ge2_after_PHR==1)

keep if drop_post_PHR != 1
count

drop if trt_PHR==1 & trt_plan_has_pre_PHR==0
count

drop if trt_PHR==1 & mixed_trt_control_PHR==1
count

drop if trt_PHR==0 & mixed_trt_control_PHR==1
count

drop if trt_PHR==1 & stay_same_plan_PHR==0
count

drop if trt_PHR==0 & stay_same_plan_ctrl_PHR==0
count

keep if long_term_nh_stayer != 1
count

global inputs ///
    age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

foreach var in $inputs {
    drop if `var'==. 
}
count

replace CO=0 if CO==.
replace FIDE_HIDE=0 if FIDE_HIDE==.

egen tag_bene = tag(BENE_ID trt_PHR)
tab trt_PHR if tag_bene==1

save "enrollee_PHR_dual_ge2_11match_stayer_readm.dta", replace


* Empty final files
clear
gen BENE_ID = .
save "FINAL_matched_sample_PHR_dual_ge2_readm.dta", replace emptyok
save "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta", replace emptyok

/***************************************************
********************************************************************************
* 2019 ADOPTERS - baseline year = 2018
********************************************************************************
use "enrollee_PHR_dual_ge2_11match_stayer_readm.dta", clear
keep if year == 2018
gen treat = (plan_ge2_first_year_PHR == 2019 & plan_ge2_allpost_PHR == 1)
keep if treat==1 | plan_ge2_first_year_PHR > 2019 | missing(plan_ge2_first_year_PHR)
duplicates drop BENE_ID, force
tab treat

* Estimate propensity score
logit treat age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    CO FIDE_HIDE

predict pscore if e(sample), pr
sum pscore if e(sample)
local caliper = 0.1 * r(sd)

display "Caliper = " `caliper'


* matching use 1:1 nearest neighbor + caliper
psmatch2 treat, pscore(pscore) neighbor(1) caliper(`caliper') common noreplacement

keep if !missing(_weight) & _weight>0
tab treat

gen cohort = 2019
save "temp_PHR_dual_ge2_readm.dta", replace

use "FINAL_matched_sample_PHR_dual_ge2_readm.dta", clear
append using "temp_PHR_dual_ge2_readm.dta"
save "FINAL_matched_sample_PHR_dual_ge2_readm.dta", replace

use "temp_PHR_dual_ge2_readm.dta", clear
keep BENE_ID
append using "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta"
save "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta", replace
erase "temp_PHR_dual_ge2_readm.dta"

********************************/

********************************************************************************
* 2020 ADOPTERS - baseline year = 2019
********************************************************************************
use "enrollee_PHR_dual_ge2_11match_stayer_readm.dta", clear
keep if year == 2019
gen treat = (plan_ge2_first_year_PHR == 2020 & plan_ge2_allpost_PHR == 1)
keep if treat==1 | plan_ge2_first_year_PHR > 2020 | missing(plan_ge2_first_year_PHR)
duplicates drop BENE_ID, force
tab treat

* Estimate propensity score
logit treat age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    CO FIDE_HIDE

predict pscore if e(sample), pr
sum pscore if e(sample)
local caliper = 0.1 * r(sd)

display "Caliper = " `caliper'


* matching use 1:1 nearest neighbor + caliper
psmatch2 treat, pscore(pscore) neighbor(1) caliper(`caliper') common noreplacement

keep if !missing(_weight) & _weight>0
tab treat

gen cohort = 2020
save "temp_PHR_dual_ge2_readm.dta", replace

use "FINAL_matched_sample_PHR_dual_ge2_readm.dta", clear
append using "temp_PHR_dual_ge2_readm.dta"
save "FINAL_matched_sample_PHR_dual_ge2_readm.dta", replace

use "temp_PHR_dual_ge2_readm.dta", clear
keep BENE_ID
append using "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta"
save "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta", replace
erase "temp_PHR_dual_ge2_readm.dta"

********************************************************************************
* 2021 ADOPTERS - baseline year = 2020
********************************************************************************
use "enrollee_PHR_dual_ge2_11match_stayer_readm.dta", clear
keep if year == 2020
gen treat = (plan_ge2_first_year_PHR == 2021 & plan_ge2_allpost_PHR == 1)
keep if treat==1 | plan_ge2_first_year_PHR > 2021 | missing(plan_ge2_first_year_PHR)
duplicates drop BENE_ID, force
tab treat

* Estimate propensity score
logit treat age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    CO FIDE_HIDE

predict pscore if e(sample), pr
sum pscore if e(sample)
local caliper = 0.1 * r(sd)

display "Caliper = " `caliper'


* matching use 1:1 nearest neighbor + caliper
psmatch2 treat, pscore(pscore) neighbor(1) caliper(`caliper') common noreplacement

keep if !missing(_weight) & _weight>0
tab treat

gen cohort = 2021
save "temp_PHR_dual_ge2_readm.dta", replace

use "FINAL_matched_sample_PHR_dual_ge2_readm.dta", clear
append using "temp_PHR_dual_ge2_readm.dta"
save "FINAL_matched_sample_PHR_dual_ge2_readm.dta", replace

use "temp_PHR_dual_ge2_readm.dta", clear
keep BENE_ID
append using "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta"
save "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta", replace
erase "temp_PHR_dual_ge2_readm.dta"

********************************************************************************
* 2022 ADOPTERS - baseline year = 2021
********************************************************************************
use "enrollee_PHR_dual_ge2_11match_stayer_readm.dta", clear
keep if year == 2021
gen treat = (plan_ge2_first_year_PHR == 2022 & plan_ge2_allpost_PHR == 1)
keep if treat==1 | plan_ge2_first_year_PHR > 2022 | missing(plan_ge2_first_year_PHR)
duplicates drop BENE_ID, force

tab treat

* Estimate propensity score
logit treat age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke ///
    CO FIDE_HIDE

predict pscore if e(sample), pr
sum pscore if e(sample)
local caliper = 0.1 * r(sd)

display "Caliper = " `caliper'


* matching use 1:1 nearest neighbor + caliper
psmatch2 treat, pscore(pscore) neighbor(1) caliper(`caliper') common noreplacement

keep if !missing(_weight) & _weight>0
tab treat

gen cohort = 2022
save "temp_PHR_dual_ge2_readm.dta", replace

use "FINAL_matched_sample_PHR_dual_ge2_readm.dta", clear
append using "temp_PHR_dual_ge2_readm.dta"
save "FINAL_matched_sample_PHR_dual_ge2_readm.dta", replace

use "temp_PHR_dual_ge2_readm.dta", clear
keep BENE_ID
append using "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta"
save "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta", replace
erase "temp_PHR_dual_ge2_readm.dta"


********************************************************************************
* FINAL STEP 2: Create the full analysis panel (all years, all outcomes)
********************************************************************************
use "FINAL_matched_bene_list_PHR_dual_ge2_readm.dta", clear
duplicates report BENE_ID
duplicates drop BENE_ID, force
save "FINAL_matched_bene_list_CLEAN_PHR_dual_ge2_readm.dta", replace

use "enrollee_PHR_dual_ge2_11match_stayer_readm.dta", clear

* Keep ONLY the matched beneficiaries (treated + their controls)
merge m:1 BENE_ID using "FINAL_matched_bene_list_CLEAN_PHR_dual_ge2_readm.dta", keep(match) nogen

* treated plans must satisfy plan_ge2_allpost_PHR==1
replace plan_ge2_first_year_PHR = . if plan_ge2_first_year_PHR < . & ///
    plan_ge2_allpost_PHR != 1

* GE2 treatment indicators for DiD / event study
gen treated_ge2_PHR = (plan_ge2_first_year_PHR < .)
gen post_ge2_PHR = (year >= plan_ge2_first_year_PHR & plan_ge2_first_year_PHR < .)
gen trt_post_ge2_PHR  = treated_ge2_PHR * post_ge2_PHR

save "baseline_matched_PHR_dual_ge2_11match_enrollee_stayer_readm.dta", replace
count
tab treated


* Check distribution
    use "FINAL_matched_sample_PHR_dual_ge2_readm.dta", clear 

    bys treat: sum /// 
        age_64 age_6569 age_7074 age_7579 age_8084 age_85 female ///
    white black hispanic asian other_race ///
    frailty_score rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke /// 
    CO FIDE_HIDE readm_ind


log close

