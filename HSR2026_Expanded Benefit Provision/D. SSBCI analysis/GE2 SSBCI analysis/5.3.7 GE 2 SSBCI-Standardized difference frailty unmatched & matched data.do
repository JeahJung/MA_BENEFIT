cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "5.3.7 GE 2 SSBCI-Standardized difference frailty unmatched & matched data 4-9-2026.log", replace
****************************************************************************************
* Purpose: descriptive of unmatched & matched nondual data
* Input file: baseline_matched_SSBCI_nondual_ge2_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_ge2_11match_enrollee_stayer
*             did_anal_stayer
* 4-9-2026 by Ge
****************************************************************************************

* ============ Nondual unmatched ============
use "baseline_unmatched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer.dta", clear

local allvars ///
    AGE_AT_END_REF_YR ///
    female age_64 age_6569 age_7074 age_7579 age_8084 age_85 ///
    asian hispanic black white other_race ///
    frailty_score ///
    anemia ra_oa breast colon endometrial lung prostate urologic ami afib ischemic ckd alzheimers ///
    oth_dementia depress diabetes heart_failure asthma copd pneumonia parkinsons stroke ///
    rbed rmd rsnfbed rural pct_4year pct_englonly pct_undfpl ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

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


* ============ Nondual matched ============
use baseline_matched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer, clear
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
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

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


* ============ Dual unmatched ============
use "baseline_unmatched_SSBCI_dual_frailty_ge2_11match_enrollee_stayer.dta", clear

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
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

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


* ============ Dual matched ============
use baseline_matched_SSBCI_dual_frailty_ge2_11match_enrollee_stayer, clear
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
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

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

