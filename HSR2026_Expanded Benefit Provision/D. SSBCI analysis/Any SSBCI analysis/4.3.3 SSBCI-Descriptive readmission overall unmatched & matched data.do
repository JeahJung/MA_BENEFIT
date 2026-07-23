cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "3.3.3 SSBCI-Descriptive readmission overall unmatched & matched data 3-22-2026.log", replace
****************************************************************************************
* Purpose: descriptive of unmatched & matched nondual data
* Input file: baseline_matched_SSBCI_nondual_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_11match_enrollee_stayer
*             did_anal_stayer
* 3-19-2026 by Ge
****************************************************************************************


/*********************************************/
* ============ Nondual unmatched ============
/*********************************************/
use "enrollee_SSBCI_nondual_11match_stayer_readm.dta", clear
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
    readm_ind

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
    readm_ind


* ============ Nondual matched ============
use baseline_matched_SSBCI_nondual_11match_enrollee_stayer_readm, clear
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
    readm_ind

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
    readm_ind



/*********************************************/
* ============ Dual unmatched ============
/*********************************************/
use "enrollee_SSBCI_dual_11match_stayer_readm.dta", clear
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
    readm_ind

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
    readm_ind


/***************************************************/
* ============ Dual matched ============
/***************************************************/
use baseline_matched_SSBCI_dual_11match_enrollee_stayer_readm, clear
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
    readm_ind

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
    readm_ind



log close

