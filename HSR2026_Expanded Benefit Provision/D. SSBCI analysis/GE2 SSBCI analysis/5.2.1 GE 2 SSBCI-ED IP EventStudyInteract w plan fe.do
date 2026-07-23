cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "5.2.1 GE 2 SSBCI-ED IP EventStudyInteract w plan fe 3-20-2026.log", replace
*************************************************************************************
* Purpose: Use both xtreg and EventStudyInteract, run DiD model for Any SSBCI for nondual & dual separately after baseline matching.
*          1. Overall
*          2. Limit to top frailty scores (frailty tertile)
* Input file: baseline_matched_SSBCI_nondual_ge2_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_ge2_11match_enrollee_stayer
*             baseline_matched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_frailty_ge2_11match_enrollee_stayer
* 3-18-2026 by Ge
*************************************************************************************


/****************************************/
* Non dual
/****************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_nondual_ge2_11match_enrollee_stayer, clear
count

bys trt_SSBCI: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

* never-treated plans: set to 0
replace g_SSBCI = 0 if missing(g_SSBCI)

* create never-treated cohort indicator
gen never_SSBCI = (g_SSBCI == 0)

* create lead/lag dummies from time_l_SSBCI
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2 -> P_0 P_1 P_2

forvalues t = -5/2 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_SSBCI == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_SSBCI == `t')
    }
}


foreach y in $outcome {

    di "************ Matched Non-Dual eventstudyinteract - `y' of Any SSBCI ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2)/3

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2   // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar Ntot = N0 + N1 + N2
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2

************ weighted average for pre-period parallel trend test
    * simple average pre-treatment effect over pre periods
    lincom (M_5 + M_4 + M_3 + M_2)/4

    * n-weighted average post-treatment effect over pre periods
    ** Compute counts for each pre dummy
    preserve
    collapse (sum) M_5 M_4 M_3 M_2 
    scalar N0 = M_5
    scalar N1 = M_4
    scalar N2 = M_3
    scalar N3 = M_2
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*M_5 + w1*M_4 + w2*M_3 + w3*M_2

    * event study pre-trend test
    test M_5 M_4 M_3 M_2

}



/****************************************/
* Dual
/****************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_dual_ge2_11match_enrollee_stayer, clear
count

bys trt_SSBCI: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    CO FIDE_HIDE

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

* never-treated plans: set to 0
replace g_SSBCI = 0 if missing(g_SSBCI)

* create never-treated cohort indicator
gen never_SSBCI = (g_SSBCI == 0)

* create lead/lag dummies from time_l_SSBCI
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2 -> P_0 P_1 P_2

forvalues t = -5/2 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_SSBCI == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_SSBCI == `t')
    }
}

foreach y in $outcome {

di "************ Matched Dual eventstudyinteract - `y' of Any SSBCI ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2)/3

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2   // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar Ntot = N0 + N1 + N2
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2

************ weighted average for pre-period parallel trend test
    * simple average pre-treatment effect over pre periods
    lincom (M_5 + M_4 + M_3 + M_2)/4

    * n-weighted average post-treatment effect over pre periods
    ** Compute counts for each pre dummy
    preserve
    collapse (sum) M_5 M_4 M_3 M_2 
    scalar N0 = M_5
    scalar N1 = M_4
    scalar N2 = M_3
    scalar N3 = M_2
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*M_5 + w1*M_4 + w2*M_3 + w3*M_2

    * event study pre-trend test
    test M_5 M_4 M_3 M_2

}


/****************************************/
* Non dual-frailty
/****************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_nondual_frailty_ge2_11match_enrollee_stayer, clear
count

bys trt_SSBCI: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

* never-treated plans: set to 0
replace g_SSBCI = 0 if missing(g_SSBCI)

* create never-treated cohort indicator
gen never_SSBCI = (g_SSBCI == 0)

* create lead/lag dummies from time_l_SSBCI
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2 -> P_0 P_1 P_2

forvalues t = -5/2 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_SSBCI == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_SSBCI == `t')
    }
}


foreach y in $outcome {

    di "************ Matched Non-Dual limit to frailty eventstudyinteract - `y' of Any SSBCI ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2)/3

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2   // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar Ntot = N0 + N1 + N2
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2

************ weighted average for pre-period parallel trend test
    * simple average pre-treatment effect over pre periods
    lincom (M_5 + M_4 + M_3 + M_2)/4

    * n-weighted average post-treatment effect over pre periods
    ** Compute counts for each pre dummy
    preserve
    collapse (sum) M_5 M_4 M_3 M_2 
    scalar N0 = M_5
    scalar N1 = M_4
    scalar N2 = M_3
    scalar N3 = M_2
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*M_5 + w1*M_4 + w2*M_3 + w3*M_2

    * event study pre-trend test
    test M_5 M_4 M_3 M_2

}



/****************************************/
* Dual-frailty
/****************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_dual_frailty_ge2_11match_enrollee_stayer, clear
count

bys trt_SSBCI: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    CO FIDE_HIDE

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll InHomeSupportServ TherapeuticMassage

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

* never-treated plans: set to 0
replace g_SSBCI = 0 if missing(g_SSBCI)

* create never-treated cohort indicator
gen never_SSBCI = (g_SSBCI == 0)

* create lead/lag dummies from time_l_SSBCI
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2 -> P_0 P_1 P_2

forvalues t = -5/2 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_SSBCI == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_SSBCI == `t')
    }
}

foreach y in $outcome {

di "************ Matched Dual limit to frailty eventstudyinteract - `y' of Any SSBCI ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2)/3

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2   // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar Ntot = N0 + N1 + N2
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2

************ weighted average for pre-period parallel trend test
    * simple average pre-treatment effect over pre periods
    lincom (M_5 + M_4 + M_3 + M_2)/4

    * n-weighted average post-treatment effect over pre periods
    ** Compute counts for each pre dummy
    preserve
    collapse (sum) M_5 M_4 M_3 M_2 
    scalar N0 = M_5
    scalar N1 = M_4
    scalar N2 = M_3
    scalar N3 = M_2
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*M_5 + w1*M_4 + w2*M_3 + w3*M_2

    * event study pre-trend test
    test M_5 M_4 M_3 M_2
}





log close
