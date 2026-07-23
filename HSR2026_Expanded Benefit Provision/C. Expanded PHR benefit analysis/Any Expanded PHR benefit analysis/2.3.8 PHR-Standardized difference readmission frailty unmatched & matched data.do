cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "2.3.8 PHR-Standardized difference readmission frailty unmatched & matched data 3-23-2026.log", replace
****************************************************************************************
* Purpose: descriptive of overall unmatched & matched nondual data
* Input file: baseline_matched_PHR_nondual_11match_enrollee_stayer_readm
*             baseline_matched_PHR_dual_11match_enrollee_stayer_readm
*             did_stayer_readm
* 3-23-2026 by Ge
****************************************************************************************

/*********************************************/
* ============ Nondual unmatched ============
/*********************************************/
use "enrollee_PHR_nondual_frailty_11match_stayer_readm.dta", clear
count

* create cohort copies: 2019, 2020, 2021, 2022
expand 4
bysort BENE_ID year: gen copy_id = _n
gen cohort = 2018 + copy_id
drop copy_id

* keep treated cohort + not-yet-treated + never-treated controls
keep if plan_adopt_year_PHR == cohort | plan_adopt_year_PHR > cohort | missing(plan_adopt_year_PHR)

* baseline year for each cohort
gen baseline_year = cohort - 1

* baseline frailty score only in the cohort-specific baseline year
gen frailty_base = frailty_score if year == baseline_year

* carry baseline frailty score to all years within beneficiary and cohort
bysort cohort BENE_ID: egen frailty_base2 = max(frailty_base)
drop frailty_base
rename frailty_base2 frailty_base

* define frailty tertile using baseline frailty within each cohort
egen frailty_tertile0 = xtile(frailty_base), by(cohort) n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

label define frailty3 1 "High frailty" 2 "Middle frailty" 3 "Low frailty"
label values frailty_tertile frailty3

* keep unmatched high-frailty subgroup at enrollee-year level
keep if frailty_tertile == 1

* check
tab cohort trt_PHR

local allvars ///
    AGE_AT_END_REF_YR ///
    female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

foreach var in `allvars' {

    capture confirm numeric variable `var'
    if _rc == 0 {

        quietly summarize `var', meanonly
        local min = r(min)
        local max = r(max)

        if (`min'==0 & `max'==1) | (`min'==0 & `max'==0) | (`min'==1 & `max'==1) {
            quietly tab trt_PHR `var', matcell(mx)

            scalar p_control   = mx[1,2] / (mx[1,1] + mx[1,2])
            scalar p_treatment = mx[2,2] / (mx[2,1] + mx[2,2])
            scalar sd_pooled   = sqrt((p_treatment*(1-p_treatment) + p_control*(1-p_control))/2)
            scalar std_diff    = (p_treatment - p_control) / sd_pooled

            display "`var'" _column(32) %9.4f std_diff
        }
        else {
            quietly ttest `var', by(trt_PHR)

            scalar mean_control   = r(mu_1)
            scalar mean_treatment = r(mu_2)
            scalar sd_control     = r(sd_1)
            scalar sd_treatment   = r(sd_2)

            scalar sd_pooled_cont = sqrt((sd_treatment^2 + sd_control^2)/2)
            scalar std_diff_cont  = (mean_treatment - mean_control) / sd_pooled_cont

            display "`var'" _column(32) %9.4f std_diff_cont
        }
    }
}


/*********************************************/
* ============ Nondual matched ============
/*********************************************/
use baseline_matched_PHR_nondual_frailty_11match_enrollee_stayer_readm, clear
count

local allvars ///
    AGE_AT_END_REF_YR ///
    female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

foreach var in `allvars' {

    capture confirm numeric variable `var'
    if _rc == 0 {

        quietly summarize `var', meanonly
        local min = r(min)
        local max = r(max)

        if (`min'==0 & `max'==1) | (`min'==0 & `max'==0) | (`min'==1 & `max'==1) {
            quietly tab trt_PHR `var', matcell(mx)

            scalar p_control   = mx[1,2] / (mx[1,1] + mx[1,2])
            scalar p_treatment = mx[2,2] / (mx[2,1] + mx[2,2])
            scalar sd_pooled   = sqrt((p_treatment*(1-p_treatment) + p_control*(1-p_control))/2)
            scalar std_diff    = (p_treatment - p_control) / sd_pooled

            display "`var'" _column(32) %9.4f std_diff
        }
        else {
            quietly ttest `var', by(trt_PHR)

            scalar mean_control   = r(mu_1)
            scalar mean_treatment = r(mu_2)
            scalar sd_control     = r(sd_1)
            scalar sd_treatment   = r(sd_2)

            scalar sd_pooled_cont = sqrt((sd_treatment^2 + sd_control^2)/2)
            scalar std_diff_cont  = (mean_treatment - mean_control) / sd_pooled_cont

            display "`var'" _column(32) %9.4f std_diff_cont
        }
    }
}



/*********************************************/
* ============ Dual unmatched ============
/*********************************************/
use "enrollee_PHR_dual_frailty_11match_stayer_readm.dta", clear
count

* create cohort copies: 2019, 2020, 2021, 2022
expand 4
bysort BENE_ID year: gen copy_id = _n
gen cohort = 2018 + copy_id
drop copy_id

* keep treated cohort + not-yet-treated + never-treated controls
keep if plan_adopt_year_PHR == cohort | plan_adopt_year_PHR > cohort | missing(plan_adopt_year_PHR)

* baseline year for each cohort
gen baseline_year = cohort - 1

* baseline frailty score only in the cohort-specific baseline year
gen frailty_base = frailty_score if year == baseline_year

* carry baseline frailty score to all years within beneficiary and cohort
bysort cohort BENE_ID: egen frailty_base2 = max(frailty_base)
drop frailty_base
rename frailty_base2 frailty_base

* define frailty tertile using baseline frailty within each cohort
egen frailty_tertile0 = xtile(frailty_base), by(cohort) n(3)
gen frailty_tertile = 4 - frailty_tertile0
drop frailty_tertile0

label define frailty3 1 "High frailty" 2 "Middle frailty" 3 "Low frailty"
label values frailty_tertile frailty3

* keep unmatched high-frailty subgroup at enrollee-year level
keep if frailty_tertile == 1

* check
tab cohort trt_PHR

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
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

foreach var in `allvars' {

    capture confirm numeric variable `var'
    if _rc == 0 {

        quietly summarize `var', meanonly
        local min = r(min)
        local max = r(max)

        if (`min'==0 & `max'==1) | (`min'==0 & `max'==0) | (`min'==1 & `max'==1) {
            quietly tab trt_PHR `var', matcell(mx)

            scalar p_control   = mx[1,2] / (mx[1,1] + mx[1,2])
            scalar p_treatment = mx[2,2] / (mx[2,1] + mx[2,2])
            scalar sd_pooled   = sqrt((p_treatment*(1-p_treatment) + p_control*(1-p_control))/2)
            scalar std_diff    = (p_treatment - p_control) / sd_pooled

            display "`var'" _column(32) %9.4f std_diff
        }
        else {
            quietly ttest `var', by(trt_PHR)

            scalar mean_control   = r(mu_1)
            scalar mean_treatment = r(mu_2)
            scalar sd_control     = r(sd_1)
            scalar sd_treatment   = r(sd_2)

            scalar sd_pooled_cont = sqrt((sd_treatment^2 + sd_control^2)/2)
            scalar std_diff_cont  = (mean_treatment - mean_control) / sd_pooled_cont

            display "`var'" _column(32) %9.4f std_diff_cont
        }
    }
}


/*********************************************/
* ============ Dual matched ============
/*********************************************/
use baseline_matched_PHR_dual_frailty_11match_enrollee_stayer_readm, clear
count

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
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

foreach var in `allvars' {

    capture confirm numeric variable `var'
    if _rc == 0 {

        quietly summarize `var', meanonly
        local min = r(min)
        local max = r(max)

        if (`min'==0 & `max'==1) | (`min'==0 & `max'==0) | (`min'==1 & `max'==1) {
            quietly tab trt_PHR `var', matcell(mx)

            scalar p_control   = mx[1,2] / (mx[1,1] + mx[1,2])
            scalar p_treatment = mx[2,2] / (mx[2,1] + mx[2,2])
            scalar sd_pooled   = sqrt((p_treatment*(1-p_treatment) + p_control*(1-p_control))/2)
            scalar std_diff    = (p_treatment - p_control) / sd_pooled

            display "`var'" _column(32) %9.4f std_diff
        }
        else {
            quietly ttest `var', by(trt_PHR)

            scalar mean_control   = r(mu_1)
            scalar mean_treatment = r(mu_2)
            scalar sd_control     = r(sd_1)
            scalar sd_treatment   = r(sd_2)

            scalar sd_pooled_cont = sqrt((sd_treatment^2 + sd_control^2)/2)
            scalar std_diff_cont  = (mean_treatment - mean_control) / sd_pooled_cont

            display "`var'" _column(32) %9.4f std_diff_cont
        }
    }
}



log close

