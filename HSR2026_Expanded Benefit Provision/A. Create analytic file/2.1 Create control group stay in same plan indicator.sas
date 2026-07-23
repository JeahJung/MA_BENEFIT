***************************************************************************
* Program name: 2.1.1 Create control group stay in same plan indicator.sas    
* Purpose: For PHR benefits, 
/*         Create control-group stayer=1 if a control enrollee stays in the same plan 
/*         from 2018 and all post-2018 observed years while they are observed in the sample.
/*         For SSBCI benefits,
/*         Create control-group stayer=1 if a control enrollee stays in the same plan 
/*         from 2019 for and all post-2019 observed years while they are observed in the sample.
* Input file: itt.did_&short..sas7bdat;
* By Ge Song;
* 03-10-2026;
***************************************************************************;

libname itt "&myfiles_root./dua_&dua./SAS/Benefit_ITT/Data_Files" compress=yes;

%macro cntl_stay(short=);

/**************************************************************************
* Control-group stayer for PHRs
*
* Definition:
* - enrollee is never treated: ever_treated = 0
* - enrollee stays in the same contract_plan_id from 2018 onward
* - i.e., across all observed years with year >= 2018
**************************************************************************/

/*--------------------------------------------------------------*
 | 1. Bene-level ever-treated flag
 *--------------------------------------------------------------*/
proc sql;
    create table bene_treat_status_&short. as
    select
        bene_id,
        max(trt_&short.) as ever_treated
    from itt.did_&short.
    group by bene_id;
quit;


/*--------------------------------------------------------------*
 | 2. Keep pure controls only
 *--------------------------------------------------------------*/
proc sql;
    create table pure_ctrl_&short. as
    select a.*
    from itt.did_&short. as a
    inner join bene_treat_status_&short. as b
        on a.bene_id = b.bene_id
    where b.ever_treated = 0;
quit;


/*--------------------------------------------------------------*
 | 3. Bene-level count of observed years from 2018 onward
 *--------------------------------------------------------------*/
proc sql;
    create table ctrl_policy_window_&short. as
    select
        bene_id,
        count(distinct case when year >= 2018 then year end) as bene_policy_n,
        min(case when year >= 2018 then year end) as bene_policy_min_year,
        max(case when year >= 2018 then year end) as bene_policy_max_year
    from pure_ctrl_&short.
    group by bene_id;
quit;


/*--------------------------------------------------------------*
 | 4. Bene x plan counts from 2018 onward
 *--------------------------------------------------------------*/
proc sql;
    create table control_stayer_&short. as
    select
        a.bene_id,
        a.contract_plan_id,
        max(b.ever_treated) as ever_treated,
        max(c.bene_policy_n) as bene_policy_n,
        max(c.bene_policy_min_year) as bene_policy_min_year,
        max(c.bene_policy_max_year) as bene_policy_max_year,
        count(distinct case when a.year >= 2018 then a.year end) as bene_plan_policy_n,
        min(case when a.year >= 2018 then a.year end) as bene_plan_policy_min_year,
        max(case when a.year >= 2018 then a.year end) as bene_plan_policy_max_year,
        case
            when calculated ever_treated = 0
             and calculated bene_policy_n > 0
             and calculated bene_plan_policy_n = calculated bene_policy_n
            then 1
            else 0
        end as stay_same_plan_ctrl_&short.
    from pure_ctrl_&short. as a
    left join bene_treat_status_&short. as b
        on a.bene_id = b.bene_id
    left join ctrl_policy_window_&short. as c
        on a.bene_id = c.bene_id
    group by a.bene_id, a.contract_plan_id;
quit;

/*--------------------------------------------------------------*
 | 5. Merge back to did_&short.
 *--------------------------------------------------------------*/
proc sql;
    create table did_&short. as
    select
        a.*,
        case
            when b.stay_same_plan_ctrl_&short. = 1 then 1
            else 0
        end as stay_same_plan_ctrl_&short.
    from itt.did_&short. as a
    left join control_stayer_&short. as b
        on a.bene_id = b.bene_id
       and a.contract_plan_id = b.contract_plan_id;
quit;



/************** CHECK ********************/
title "Basic frequency";
proc freq data=control_stayer_&short.;
    tables stay_same_plan_ctrl_&short. / missing;
run;

title "counts the number of distinct plans they had during the required window";
proc sql;
    create table ctrl_policy_plan_check_&short. as
    select
        bene_id,
        count(distinct case when year >= 2018 then contract_plan_id end) as n_policy_plans
    from pure_ctrl_&short.
    group by bene_id;
quit;

proc sql;
    create table ctrl_policy_flag_check_&short. as
    select
        a.bene_id,
        a.n_policy_plans,
        sum(b.stay_same_plan_ctrl_&short.) as n_flag1_plans
    from ctrl_policy_plan_check_&short. as a
    left join control_stayer_&short. as b
        on a.bene_id = b.bene_id
    group by a.bene_id, a.n_policy_plans;
quit;

proc freq data=ctrl_policy_flag_check_&short.;
    tables n_policy_plans * n_flag1_plans / missing;
run;
title;

%mend cntl_stay;

%cntl_stay(short=PHR);
%cntl_stay(short=IHSS);



%macro cntl_stay_SSBCI(short=);

/**************************************************************************
* Control-group stayer for SSBCIs
*
* Definition:
* - enrollee is never treated: ever_treated = 0
* - enrollee stays in the same contract_plan_id from 2019 onward
* - i.e., across all observed years with year >= 2019
**************************************************************************/

/*--------------------------------------------------------------*
 | 1. Bene-level ever-treated flag
 *--------------------------------------------------------------*/
proc sql;
    create table bene_treat_status_&short. as
    select
        bene_id,
        max(trt_&short.) as ever_treated
    from itt.did_&short.
    group by bene_id;
quit;


/*--------------------------------------------------------------*
 | 2. Keep pure controls only
 *--------------------------------------------------------------*/
proc sql;
    create table pure_ctrl_&short. as
    select a.*
    from itt.did_&short. as a
    inner join bene_treat_status_&short. as b
        on a.bene_id = b.bene_id
    where b.ever_treated = 0;
quit;


/*--------------------------------------------------------------*
 | 3. Bene-level count of observed years from 2019 onward
 *--------------------------------------------------------------*/
proc sql;
    create table ctrl_policy_window_&short. as
    select
        bene_id,
        count(distinct case when year >= 2019 then year end) as bene_policy_n,
        min(case when year >= 2019 then year end) as bene_policy_min_year,
        max(case when year >= 2019 then year end) as bene_policy_max_year
    from pure_ctrl_&short.
    group by bene_id;
quit;


/*--------------------------------------------------------------*
 | 4. Bene x plan counts from 2019 onward
 *--------------------------------------------------------------*/
proc sql;
    create table control_stayer_&short. as
    select
        a.bene_id,
        a.contract_plan_id,
        max(b.ever_treated) as ever_treated,
        max(c.bene_policy_n) as bene_policy_n,
        max(c.bene_policy_min_year) as bene_policy_min_year,
        max(c.bene_policy_max_year) as bene_policy_max_year,
        count(distinct case when a.year >= 2019 then a.year end) as bene_plan_policy_n,
        min(case when a.year >= 2019 then a.year end) as bene_plan_policy_min_year,
        max(case when a.year >= 2019 then a.year end) as bene_plan_policy_max_year,
        case
            when calculated ever_treated = 0
             and calculated bene_policy_n > 0
             and calculated bene_plan_policy_n = calculated bene_policy_n
            then 1
            else 0
        end as stay_same_plan_ctrl_&short.
    from pure_ctrl_&short. as a
    left join bene_treat_status_&short. as b
        on a.bene_id = b.bene_id
    left join ctrl_policy_window_&short. as c
        on a.bene_id = c.bene_id
    group by a.bene_id, a.contract_plan_id;
quit;

/*--------------------------------------------------------------*
 | 5. Merge back to did_&short.
 *--------------------------------------------------------------*/
proc sql;
    create table did_&short. as
    select
        a.*,
        case
            when b.stay_same_plan_ctrl_&short. = 1 then 1
            else 0
        end as stay_same_plan_ctrl_&short.
    from itt.did_&short. as a
    left join control_stayer_&short. as b
        on a.bene_id = b.bene_id
       and a.contract_plan_id = b.contract_plan_id;
quit;



/************** CHECK ********************/
title "Basic frequency";
proc freq data=control_stayer_&short.;
    tables stay_same_plan_ctrl_&short. / missing;
run;

title "counts the number of distinct plans they had during the required window";
proc sql;
    create table ctrl_policy_plan_check_&short. as
    select
        bene_id,
        count(distinct case when year >= 2019 then contract_plan_id end) as n_policy_plans
    from pure_ctrl_&short.
    group by bene_id;
quit;

proc sql;
    create table ctrl_policy_flag_check_&short. as
    select
        a.bene_id,
        a.n_policy_plans,
        sum(b.stay_same_plan_ctrl_&short.) as n_flag1_plans
    from ctrl_policy_plan_check_&short. as a
    left join control_stayer_&short. as b
        on a.bene_id = b.bene_id
    group by a.bene_id, a.n_policy_plans;
quit;

proc freq data=ctrl_policy_flag_check_&short.;
    tables n_policy_plans * n_flag1_plans / missing;
run;
title;

%mend cntl_stay_SSBCI;

%cntl_stay_SSBCI(short=SSBCI);
%cntl_stay_SSBCI(short=FS);
%cntl_stay_SSBCI(short=HQ);