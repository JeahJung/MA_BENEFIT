cd "/home/gso275/files/dua_056684/Stata/Benefit_ITT_Revise"
capture log close
log using "3.2.6 SSBCI-honestdid wider x-axis 3-27-2026.log", replace
*************************************************************************************
* Purpose: Run honestDiD for ED, IP and readmission
* Input file: baseline_matched_SSBCI_nondual_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_11match_enrollee_stayer
*             baseline_matched_SSBCI_nondual_frailty_11match_enrollee_stayer
*             baseline_matched_SSBCI_dual_frailty_11match_enrollee_stayer
*             baseline_matched_SSBCI_nondual_11match_enrollee_readm
*             baseline_matched_SSBCI_dual_11match_enrollee_readm
*             baseline_matched_SSBCI_nondual_frailty_11match_enrollee_readm
*             baseline_matched_SSBCI_dual_frailty_11match_enrollee_readm
* 3-26-2026 by Ge
*************************************************************************************

/************************************/
* Non dual 
/************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_nondual_11match_enrollee_stayer, clear
count

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

bys trt_SSBCI: sum ED_ind IP_ind

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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
    di "************ Matched Non-Dual eventstudyinteract - ED of Any SSBCI ************"
    eventstudyinteract ED_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on ED use") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_nondual_ED_2.png", replace
    restore

    di "************ Matched Non-Dual eventstudyinteract - IP of Any SSBCI ************"
    eventstudyinteract IP_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on hospitalization") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_nondual_IP_2.png", replace
    restore



/************************************/
* Non dual-frailty
/************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_nondual_frailty_11match_enrollee_stayer, clear
count

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

bys trt_SSBCI: sum ED_ind IP_ind

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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

    di "************ Matched Non-Dual frailty eventstudyinteract - ED of Any SSBCI ************"
    eventstudyinteract ED_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on ED use") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_nondual_frailty_ED_2.png", replace
    restore

    di "************ Matched Non-Dual frailty eventstudyinteract - IP of Any SSBCI ************"
    eventstudyinteract IP_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on hospitalization") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_nondual_frailty_IP_2.png", replace
    restore



/************************************/
* Dual 
/************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_dual_11match_enrollee_stayer, clear
count

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

bys trt_SSBCI: sum ED_ind IP_ind

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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

di "************ Matched Dual eventstudyinteract - ED of Any SSBCI ************"
    eventstudyinteract ED_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on ED use") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_dual_ED_2.png", replace
    restore

di "************ Matched Dual eventstudyinteract - IP of Any SSBCI ************"
    eventstudyinteract IP_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on hospitalization") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_dual_IP_2.png", replace
    restore




/************************************/
* Dual frailty
/************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_dual_frailty_11match_enrollee_stayer, clear
count

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

bys trt_SSBCI: sum ED_ind IP_ind

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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

di "************ Matched Dual frailty eventstudyinteract - ED of Any SSBCI ************"
    eventstudyinteract ED_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on ED use") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_dual_frailty_ED_2.png", replace
    restore

di "************ Matched Dual frailty eventstudyinteract - IP of Any SSBCI ************"
    eventstudyinteract IP_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)
    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            ytitle("Average effect on hospitalization") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_dual_frailty_IP_2.png", replace
    restore


/********************************************/
* Non dual readmission
/********************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_nondual_11match_enrollee_stayer_readm, clear
count

bys trt_SSBCI: sum readm_ind

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

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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

    di "************ Matched Non-Dual eventstudyinteract - readm of Any SSBCI ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)

    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on re-admission") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_nondual_readm_2.png", replace
    restore



/********************************************/
* Non dual frailty readmission
/********************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_nondual_frailty_11match_enrollee_stayer_readm, clear
count

bys trt_SSBCI: sum readm_ind

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

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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

    di "************ Matched Non-Dual frailty eventstudyinteract - readm of Any SSBCI ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)

    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on re-admission") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_nondual_frailty_readm_2.png", replace
    restore



/********************************************/
* Dual readmission
/********************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_dual_11match_enrollee_stayer_readm, clear
count

bys trt_SSBCI: sum readm_ind

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

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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

di "************ Matched Dual eventstudyinteract - readm of Any SSBCI ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)

    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on re-admission") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_dual_readm_2.png", replace
    restore



/********************************************/
* Dual frailty readmssion
/********************************************/
clear
set sortseed 12345
use baseline_matched_SSBCI_dual_frailty_11match_enrollee_stayer_readm, clear
count

bys trt_SSBCI: sum readm_ind

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

egen plan_county = group(contract_plan_id county_SSA)
xtset plan_county

* first treatment year per plan
bysort contract_plan_id: egen g_SSBCI = min(cond(trt_post_SSBCI==1, year, .))

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

di "************ Matched Dual frailty eventstudyinteract - readm of Any SSBCI ************"
    eventstudyinteract readm_ind M_5 M_4 M_3 M_2 P_0 P_1 P_2, cohort(g_SSBCI) control_cohort(never_SSBCI) covariates($supp_benefit $X $condition) absorb(i.plan_county i.year) vce(cluster plan_county)

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

    * Average post effect (n-weighted over 3 post periods):
    matrix l_vec = w0, w1, w2
    honestdid, pre(1/4) post(5/7) mvec(0.5(0.5)2) l_vec(l_vec)

    tempname CI
    mata: st_matrix("`CI'", `s(HonestEventStudy)'.CI)
    matrix colnames `CI' = M lb ub
    
    preserve
        clear
        svmat double `CI', names(col)
    
        gen x = M
        replace x = 0 if missing(M)
    
        twoway ///
            (rcap lb ub x, lwidth(medthick)) ///
            (scatter lb x, msymbol(none)), ///
            yline(0, lpattern(dash)) ///
            xlabel(0 "Original" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
            xtick(0(0.5)2) ///
            xscale(range(-0.05 2.05)) ///
            ytitle("Average effect on re-admission") ///
            xtitle("") ///
            legend(off)
    
        graph export "SSBCI_dual_frailty_readm_2.png", replace
    restore




log close
