cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "4.2.2 GE 2 PHR-ED IP EventStudyInteract w plan county fe 3-20-2026.log", replace
*************************************************************************************
* Purpose: Use EventStudyInteract, run DiD model for at least two Any expanded PHR for nondual & dual separately after baseline matching.
*          1. Overall
*          2. Limit to top frailty scores (frailty tertile)
* Input file: baseline_matched_PHR_nondual_ge2_11match_enrollee_stayer
*             baseline_matched_PHR_dual_ge2_11match_enrollee_stayer
*             baseline_matched_PHR_nondual_frailty_ge2_11match_enrollee_stayer
*             baseline_matched_PHR_dual_frailty_ge2_11match_enrollee_stayer
* 3-18-2026 by Ge
*************************************************************************************

/***************************************/
* Non dual
/***************************************/
clear
set sortseed 12345
use baseline_matched_PHR_nondual_ge2_11match_enrollee_stayer, clear
count

bys trt_PHR: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural

global supp_benefit ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_PHR = min(cond(trt_post_PHR==1, year, .))

* never-treated plans: set to 0
replace g_PHR = 0 if missing(g_PHR)

* create never-treated cohort indicator
gen never_PHR = (g_PHR == 0)

* create lead/lag dummies from time_l_PHR
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_PHR == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_PHR == `t')
    }
}


foreach y in $outcome {

    di "************ Matched Non-Dual  eventstudyinteract - `y' of Any expanded PHR ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_PHR) control_cohort(never_PHR) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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
    scalar Ntot = N0 + N1 + N2 +N3
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

}



/***************************************/
* Dual
/***************************************/
clear
set sortseed 12345
use baseline_matched_PHR_dual_ge2_11match_enrollee_stayer, clear
count

bys trt_PHR: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    CO FIDE_HIDE

global supp_benefit ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_PHR = min(cond(trt_post_PHR==1, year, .))

* never-treated plans: set to 0
replace g_PHR = 0 if missing(g_PHR)

* create never-treated cohort indicator
gen never_PHR = (g_PHR == 0)

* create lead/lag dummies from time_l_PHR
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_PHR == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_PHR == `t')
    }
}

foreach y in $outcome {

di "************ Matched Dual eventstudyinteract - `y' of Any expanded PHR ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_PHR) control_cohort(never_PHR) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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
    scalar Ntot = N0 + N1 + N2 +N3
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

}




/***************************************/
* Non dual-frailty
/***************************************/
clear
set sortseed 12345
use baseline_matched_PHR_nondual_frailty_ge2_11match_enrollee_stayer, clear
count

bys trt_PHR: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural

global supp_benefit ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_PHR = min(cond(trt_post_PHR==1, year, .))

* never-treated plans: set to 0
replace g_PHR = 0 if missing(g_PHR)

* create never-treated cohort indicator
gen never_PHR = (g_PHR == 0)

* create lead/lag dummies from time_l_PHR
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_PHR == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_PHR == `t')
    }
}


foreach y in $outcome {

    di "************ Matched Non-Dual eventstudyinteract - `y' of Any expanded PHR ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_PHR) control_cohort(never_PHR) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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
    scalar Ntot = N0 + N1 + N2 +N3
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

}



/***************************************/
* Dual-frailty
/***************************************/
clear
set sortseed 12345
use baseline_matched_PHR_dual_frailty_ge2_11match_enrollee_stayer, clear
count

bys trt_PHR: sum ED_ind IP_ind

global X ///
    age_6569 age_7074 age_7579 age_8084 age_85 female ///
    black hispanic asian other_race ///
    frailty_score ///
    rbed rmd rsnfbed ///
    pct_4year pct_englonly pct_undfpl rural ///
    CO FIDE_HIDE

global supp_benefit ///
    Transportation Meal ///
    FoodSecurity HousingQuality TransportationNonMedical SocialNeedsBenefit GeneralSupportsforliving

global condition ///
    ra_oa breast colon endometrial lung prostate urologic ami ischemic afib alzheimers ///
    oth_dementia diabetes depress heart_failure anemia copd pneumonia asthma parkinsons ckd stroke

global outcome ///
    ED IP

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_PHR = min(cond(trt_post_PHR==1, year, .))

* never-treated plans: set to 0
replace g_PHR = 0 if missing(g_PHR)

* create never-treated cohort indicator
gen never_PHR = (g_PHR == 0)

* create lead/lag dummies from time_l_PHR
*    - t = -1 as the omitted base period                   
*    - leads:  -5,-4,-3,-2 -> M_5 M_4 M_3 M_2            
*    - lags: 0, 1, 2, 3 -> P_0 P_1 P_2 P_3

forvalues t = -5/3 {
    if `t' < -1 {
        local kk = abs(`t')
        gen M_`kk' = (time_l_PHR == `t')
    }
    else if `t' >= 0 {
        gen P_`t' = (time_l_PHR == `t')
    }
}


foreach y in $outcome {

di "************ Matched Dual limit to frailty eventstudyinteract - `y' of Any expanded PHR ************"
    eventstudyinteract `y'_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2 P_3, cohort(g_PHR) control_cohort(never_PHR) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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
    scalar Ntot = N0 + N1 + N2 +N3
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

}



log close
