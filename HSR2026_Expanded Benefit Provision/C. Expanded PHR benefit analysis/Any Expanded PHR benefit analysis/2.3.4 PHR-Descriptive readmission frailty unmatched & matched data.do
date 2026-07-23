cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "2.3.4 PHR-Descriptive readmission frailty unmatched & matched data 3-24-2026.log", replace
****************************************************************************************
* Purpose: descriptive of overall unmatched & matched nondual data
* Input file: baseline_matched_PHR_nondual_11match_enrollee_stayer_readm
*             baseline_matched_PHR_dual_11match_enrollee_stayer_readm
*             did_stayer_readm
* 3-19-2026 by Ge
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
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind

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
        local trt_pct : display %10.2f `trt_n'/`trt_denom'

        quietly count if trt_PHR==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_PHR==0 & !missing(`v')
        local ctrl_denom = r(N)
        local ctrl_pct : display %10.2f `ctrl_n'/`ctrl_denom'

        display as result ///
            %-24s "`v'" ///
            _col(26) %10.0f `trt_n' ///
            _col(39) "`trt_pct'" ///
            _col(53) %10.0f `ctrl_n' ///
            _col(67) "`ctrl_pct'"
    }
}

bys trt_PHR: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind


/*******************************************/
* ============ Nondual matched ============
/*******************************************/
use baseline_matched_PHR_nondual_frailty_11match_enrollee_stayer_readm, clear
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
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind

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
        local trt_pct : display %10.2f `trt_n'/`trt_denom'

        quietly count if trt_PHR==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_PHR==0 & !missing(`v')
        local ctrl_denom = r(N)
        local ctrl_pct : display %10.2f `ctrl_n'/`ctrl_denom'

        display as result ///
            %-24s "`v'" ///
            _col(26) %10.0f `trt_n' ///
            _col(39) "`trt_pct'" ///
            _col(53) %10.0f `ctrl_n' ///
            _col(67) "`ctrl_pct'"
    }
}

bys trt_PHR: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind



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
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind

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
        local trt_pct : display %10.2f `trt_n'/`trt_denom'

        quietly count if trt_PHR==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_PHR==0 & !missing(`v')
        local ctrl_denom = r(N)
        local ctrl_pct : display %10.2f `ctrl_n'/`ctrl_denom'

        display as result ///
            %-24s "`v'" ///
            _col(26) %10.0f `trt_n' ///
            _col(39) "`trt_pct'" ///
            _col(53) %10.0f `ctrl_n' ///
            _col(67) "`ctrl_pct'"
    }
}

bys trt_PHR: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    CO FIDE_HIDE ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind



* ============ Dual matched ============
use baseline_matched_PHR_dual_frailty_11match_enrollee_stayer_readm, clear
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
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind

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

bys trt_PHR: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    CO FIDE_HIDE ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving ///
    readm_ind

log close

