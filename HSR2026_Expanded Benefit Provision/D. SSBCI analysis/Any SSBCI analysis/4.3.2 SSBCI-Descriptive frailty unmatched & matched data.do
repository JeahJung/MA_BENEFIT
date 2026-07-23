cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "3.3.2 SSBCI-Descriptive frailty unmatched & matched data 3-24-2026.log", replace
****************************************************************************************
* Purpose: descriptive of overall unmatched & matched nondual data
* Input file: baseline_matched_SSBCI_nondual_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_11match_enrollee_stayer
*             did_anal_stayer
* 3-19-2026 by Ge
****************************************************************************************

/*********************************************/
* ============ Nondual frailty unmatched ============
/*********************************************/
clear
use enrollee_SSBCI_nondual_frailty_11match_stayer.dta, clear

* create cohort copies: 2020, 2021, 2022
expand 4
bysort BENE_ID year: gen copy_id = _n
gen cohort = 2019 + copy_id
drop copy_id

* keep treated cohort + not-yet-treated + never-treated controls
keep if plan_adopt_year_SSBCI == cohort | plan_adopt_year_SSBCI > cohort | missing(plan_adopt_year_SSBCI)

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
tab trt_SSBCI

egen tag_bene = tag(BENE_ID trt_SSBCI)
tab trt_SSBCI if tag_bene==1

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
        quietly summarize `v' if trt_SSBCI==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_SSBCI==0
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
        quietly count if trt_SSBCI==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_SSBCI==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_SSBCI==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_SSBCI==0 & !missing(`v')
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

bys trt_SSBCI: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind



/******************************************/
* ============ Nondual Frailty matched ============
/******************************************/
use baseline_matched_SSBCI_nondual_frailty_11match_enrollee_stayer, clear
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
        quietly summarize `v' if trt_SSBCI==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_SSBCI==0
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
        quietly count if trt_SSBCI==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_SSBCI==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_SSBCI==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_SSBCI==0 & !missing(`v')
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

bys trt_SSBCI: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind



/*********************************************/
* ============ Dual frailty unmatched ============
/*********************************************/
clear
use enrollee_SSBCI_dual_frailty_11match_stayer.dta, clear

* create cohort copies: 2020, 2021, 2022
expand 4
bysort BENE_ID year: gen copy_id = _n
gen cohort = 2019 + copy_id
drop copy_id

* keep treated cohort + not-yet-treated + never-treated controls
keep if plan_adopt_year_SSBCI == cohort | plan_adopt_year_SSBCI > cohort | missing(plan_adopt_year_SSBCI)

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
tab trt_SSBCI

egen tag_bene = tag(BENE_ID trt_SSBCI)
tab trt_SSBCI if tag_bene==1

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
        quietly summarize `v' if trt_SSBCI==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_SSBCI==0
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
        quietly count if trt_SSBCI==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_SSBCI==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_SSBCI==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_SSBCI==0 & !missing(`v')
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

bys trt_SSBCI: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    CO FIDE_HIDE ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind



/***************************************************/
* ============ Dual frailty matched ============
/***************************************************/
use baseline_matched_SSBCI_dual_frailty_11match_enrollee_stayer, clear
count

local contvars ///
    AGE_AT_END_REF_YR ///
    frailty_score ///
    rbed rmd rsnfbed pct_4year pct_englonly pct_undfpl

local allvars ///
    AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
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
        quietly summarize `v' if trt_SSBCI==1
        local trt_n   : display %10.3f r(mean)
        local trt_pct : display %10.3f r(sd)

        quietly summarize `v' if trt_SSBCI==0
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
        quietly count if trt_SSBCI==1 & `v'==1
        local trt_n = r(N)
        quietly count if trt_SSBCI==1 & !missing(`v')
        local trt_denom = r(N)
        local trt_pct : display %10.4f `trt_n'/`trt_denom'

        quietly count if trt_SSBCI==0 & `v'==1
        local ctrl_n = r(N)
        quietly count if trt_SSBCI==0 & !missing(`v')
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

bys trt_SSBCI: sum AGE_AT_END_REF_YR female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    CO FIDE_HIDE ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage ///
    ED_ind IP_ind




log close

