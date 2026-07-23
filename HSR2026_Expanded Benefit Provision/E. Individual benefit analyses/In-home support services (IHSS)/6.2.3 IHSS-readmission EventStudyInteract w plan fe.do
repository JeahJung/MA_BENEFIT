cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "6.2.3 IHSS-readmission EventStudyInteract w plan fe 3-22-2026.log", replace
*************************************************************************************
* Purpose: Use EventStudyInteract, run DiD model for readmission IHSS for nondual & dual separately after baseline matching.
*          1. Overall
*          2. Frailty
* Input file: baseline_matched_IHSS_nondual_11match_enrollee_stayer_readm
*             baseline_matched_IHSS_dual_11match_enrollee_stayer_readm
*             baseline_matched_IHSS_nondual_frailty_11match_enrollee_stayer_readm
*             baseline_matched_IHSS_dual_frailty_11match_enrollee_stayer_readm
* 3-22-2026 by Ge
*************************************************************************************


/*********************************************/
* Non dual
/*********************************************/
clear
set sortseed 12345
use baseline_matched_IHSS_nondual_11match_enrollee_stayer_readm, clear
count

bys trt_IHSS: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll TherapeuticMassage ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_IHSS = min(cond(trt_post_IHSS==1, year, .))

* never-treated plans: set to 0
replace g_IHSS = 0 if missing(g_IHSS)

* create never-treated cohort indicator
gen never_IHSS = (g_IHSS == 0)

tab time_l_IHSS

* create lead/lag dummies from time_l_IHSS
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_IHSS == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_IHSS == `t')
    }
}

    di "************ Matched Non-Dual eventstudyinteract - readm of Any IHSS ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_IHSS) control_cohort(never_IHSS) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2 + P_3)/4

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2 P_3 // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar N3 = P_3
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2 + w3*P_3

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



/*********************************************/
* Dual
/*********************************************/
clear
set sortseed 12345
use baseline_matched_IHSS_dual_11match_enrollee_stayer_readm, clear
count

bys trt_IHSS: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    CO FIDE_HIDE

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll TherapeuticMassage ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_IHSS = min(cond(trt_post_IHSS==1, year, .))

* never-treated plans: set to 0
replace g_IHSS = 0 if missing(g_IHSS)

* create never-treated cohort indicator
gen never_IHSS = (g_IHSS == 0)

* create lead/lag dummies from time_l_IHSS
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_IHSS == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_IHSS == `t')
    }
}

di "************ Matched Dual eventstudyinteract - readm of Any IHSS ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_IHSS) control_cohort(never_IHSS) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2 + P_3)/4

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2 P_3  // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar N3 = P_3
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2 + w3*P_3

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




/*********************************************/
* Non dual-frailty
/*********************************************/
clear
set sortseed 12345
use baseline_matched_IHSS_nondual_frailty_11match_enrollee_stayer_readm, clear
count

bys trt_IHSS: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll TherapeuticMassage ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_IHSS = min(cond(trt_post_IHSS==1, year, .))

* never-treated plans: set to 0
replace g_IHSS = 0 if missing(g_IHSS)

* create never-treated cohort indicator
gen never_IHSS = (g_IHSS == 0)

tab time_l_IHSS

* create lead/lag dummies from time_l_IHSS
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_IHSS == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_IHSS == `t')
    }
}

    di "************ Matched Non-Dual limit to frailty eventstudyinteract - readm of Any IHSS ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_IHSS) control_cohort(never_IHSS) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2 + P_3)/4

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2 P_3 // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar N3 = P_3
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2 + w3*P_3

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




/*********************************************/
* Dual-frailty
/*********************************************/
clear
set sortseed 12345
use baseline_matched_IHSS_dual_frailty_11match_enrollee_stayer_readm, clear
count

bys trt_IHSS: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    CO FIDE_HIDE

global supp_benefit ///
    Transportation Meal ///
    AdultDayHealthServ HomeBasedPalliative SupportCaregiversEnroll TherapeuticMassage ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

encode contract_plan_id, gen(plan_fe)
xtset plan_fe

* first treatment year per plan
bysort plan_fe: egen g_IHSS = min(cond(trt_post_IHSS==1, year, .))

* never-treated plans: set to 0
replace g_IHSS = 0 if missing(g_IHSS)

* create never-treated cohort indicator
gen never_IHSS = (g_IHSS == 0)

* create lead/lag dummies from time_l_IHSS
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_IHSS == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_IHSS == `t')
    }
}

di "************ Matched Dual limit to frailty eventstudyinteract - readm of Any IHSS ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_IHSS) control_cohort(never_IHSS) covariates($supp_benefit $X $condition) absorb(i.plan_fe i.year) vce(cluster plan_fe)

    matrix b = e(b_iw)
    matrix V = e(V_iw)
    ereturn post b V

    * simple average post-treatment effect over post periods
    lincom (P_0 + P_1 + P_2 + P_3)/4

    * n-weighted average post-treatment effect over post periods
    ** Compute counts for each post dummy
    preserve
    collapse (sum) P_0 P_1 P_2 P_3  // sums = number of obs in each event time
    scalar N0 = P_0
    scalar N1 = P_1
    scalar N2 = P_2
    scalar N3 = P_3
    scalar Ntot = N0 + N1 + N2 + N3
    scalar w0 = N0 / Ntot
    scalar w1 = N1 / Ntot
    scalar w2 = N2 / Ntot
    scalar w3 = N3 / Ntot
    restore
    
    ** Use those weights in a lincom
    lincom w0*P_0 + w1*P_1 + w2*P_2 + w3*P_3

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




log close
