***************************************************************************
* Program name: 1.2 Create DiD treatment, post, and time flags.sas    
* Purpose: 
*          1. Focus on following benefits and defined pre-/post- periods:
*             1) Traditional supplemental benefits (2019): 
*				 - Medical transportation 
*				 - Meals on a limited basis (among those hospitalized) 
*		         2017, 2018 (pre) & 2019, 2021, 2022 (post)
*			  2) Expanded PHRs (2019): 
*				 - In-home services 
*			     - Any expanded PHR
*				 2017, 2018 (pre) & 2019, 2021, 2022 (post)
*			  3) SSBCI (non-medical benefits: 2020)
*		         - Food security 
*				 - Housing quality 
*				 - General living supports
*			     - Non-medical transportation
*			     - Any SSBCI 
*			     2017, 2018, 2019 (pre) & 2021, 2022 (post)
*		   2. Create treatment group: include treatment plans only up to their benefit adoption 
*			  period. If a plan drops the benefit in year t+1, drop that observation starting 
*			  from t+1. Including only up to year t. 
*			  Do not bring them in back even though they readopt the benefit in year t+2.
*                1) Those who are in plans with a benefit.
*		         2) For a robustness check: Create a sample indicator for sample as below: 
*					Select those who stayed in the same plan in year = -1 
*					(the year before the benefit adoption) and in all post years 
*					(year =0: benefit adoption year, year=1 if applicable, and year=2 and so forth) 
*					This is a change because it requires all post years. (i.e., we don�t want any 
*					enrollees who are new to the plan after the plan started offering a benefit. )
*					This should automatically drop any newly available plan that starts their 
*					business offering the benefit.
*		   3. Create control group: 
*			     1) Those who are in plans that never adopted the benefit between 2017 and 2022. 
*			     2) For a robustness check: Create a sample indicator for sample as below:
*					who stayed in any of the control group plan throughout the study years 
*					(i.e., enrollees in plans that never offered the benefit). 
*		   4. Create a county-level indicator that has at least one plan with the benefit .
*          5. Create condition categories:
*             -	Autoimmune: ra_oa
*			  -	Cancer: breast, colon, endometrial, lung, prostate, urologic
*			  -	CVD: ami, ischemic, afib
*             -	Dementia: Alzheimer's, other dementia 
*		      -	Diabetes
*             -	Disabling Mental Health Disorders: depress
*			  -	Heart Failure, 
*             -	Hematologic Disorders: anemia 
*             -	Lung Diseases: COPD, pneumonia, asthma 
*             -	Neurologic Disorders: Parkinson's
*             -	Renal Diseases: ESRD, CKD
*             -	Stroke.
* Input file: itt.base_all.sas7bdat;
* Output file: did_&short..sas7bdat;
***************************************************************************;

libname itt "&myfiles_root./dua_&dua./SAS/Benefit_ITT/Data_Files" compress=yes;

/**************************************************************
* Clean itt.base_all data: Create condition categories.
**************************************************************/
data base_clean;
set itt.base_all;

/* Create and label condition categories */
autoimmune = (ra_oa=1);
cancer = (breast=1 or colon=1 or endometrial=1 or lung=1 or prostate=1 or urologic=1);
cvd = (ami=1 or ischemic=1 or afib=1);
dementia = (alzheimers=1 or oth_dementia=1);
diabetes = (diabetes=1);
disable_mental_health_disorders = (depress=1);
chf = (heart_failure=1);
hematologic_disorders = (anemia=1);
lung_diseases = (copd=1 or pneumonia=1 or asthma=1);
neurologic_disorders = (parkinsons=1);
stroke = (stroke=1);

/* Any chronic condition (>=1 of the 12 conditions) */
  any_chronic_condition = max(of autoimmune cancer cvd dementia diabetes
                               disable_mental_health_disorders chf
                               hematologic_disorders lung_diseases
                               neurologic_disorders ckd stroke);

/* ge2_PHR: plan offers >=2 PHR benefits */
  n_PHR = sum(of
      TherapeuticMassage
      AdultDayHealthServ
      HomeBasedPalliative
      InHomeSupportServ
      SupportCaregiversEnroll
  );
  ge2_PHR = (n_PHR >= 2);

  /* ge2_SSBCI: plan offers >=2 SSBCI benefits */
  n_SSBCI = sum(of
      FoodProduce
      Meal_BeyondLimit
      PestControl
      IndoorAirQuality
      StructuralHomeModification
      SocialNeedsBenefit
      ComplementaryTherapies
      SelfDirectingServices
      GeneralSupportforliving
      TransportationNonMedical
  );
  ge2_SSBCI = (n_SSBCI >= 2);

contract_plan_id = catx('_', contract_id, plan_id); 
if Any_SSBCI=1 or Any_Expand_PHR=1 then Any_PHR_SSBCI=1; else Any_PHR_SSBCI=0;

label autoimmune = "ra_oa condition"
	  cancer = "Any of breast or colon or endometrial or lung or prostate or urologic condition"
	  chf = "Heart failure condition"
	  cvd = "Any of ami or ischemic or afib condition"
	  dementia = "Any of alzheimers or oth_dementia condition"
	  disable_mental_health_disorders = "depress condition"
	  hematologic_disorders = "anemia condition"
	  lung_diseases = "Any of copd or pneumonia or asthma condition"
      neurologic_disorders = "parkinsons condition"
	  ge2_PHR = "plan offers >=2 expanded PHR benefits"
	  ge2_SSBCI = "plan offers >=2 SSBCI benefits";
	  Any_PHR_SSBCI = "Any expanded PHR or any SSBCI";
run;


/**************************************************************
* Step 1: Assign treat and post groups
**************************************************************/
%macro step1_flag(benefit=, short=, post_period_start=);
    proc sql;
        /* Create plan-level adoption year */
        create table adoption_&short. as
        select contract_id, 
               plan_id, 
               min(year) as plan_adopt_year_&short. /*1st year plan adopted benefit*/
        from base_clean
        where &benefit. = 1 and year >= &post_period_start.
        group by contract_id, plan_id;
    quit;

	/* Create trt, post flags */
	proc sort data=base_clean;
	by contract_id plan_id;
	run;

    data &short._did_flag;
        /* Merge plan level adoption and pre-adopters back to enrollee level data */
        merge base_clean 
              adoption_&short.;
        by contract_id plan_id;
        /* Assign treat */
        if plan_adopt_year_&short. ne . then trt_&short. = 1; /* Treat=1 if plan ever adopted benefit */
        else trt_&short. = 0; /* Treat=0 (control) if plan never adopted benefit */

		/* Define the effective adoption year */
  		if trt_&short. = 1 then effective_adopt_yr = plan_adopt_year_&short.;
  		else effective_adopt_yr = &post_period_start.;  
	    /* Assign post for treated and controls */
	    if year < effective_adopt_yr then post_&short. = 0;   /* Pre period */
	    else post_&short. = 1;                                /* Post period */

	  	/* Drop_post only meaningful for treated plans */
	  	if trt_&short. = 1 and year > plan_adopt_year_&short. and &benefit. = 0 then drop_post_&short. = 1;
	  	else drop_post_&short. = 0;

	  	drop effective_adopt_yr;

	/* trt * post */
	trt_post_&short. = (trt_&short. = 1 and post_&short. = 1);

	label plan_adopt_year_&short. = "Year when plan first adopt &benefit."
          trt_&short. = "Treatment Indicator: 1 if plan ever adopts benefit, 0 otherwise"
          post_&short. = "Post Indicator: 1 from adoption year onward for treated, 0 otherwise"
          drop_post_&short. = "Post-Drop Indicator: 1 for post-adoption discontinued years in treated plans";
    run;

%mend step1_flag;

%step1_flag(benefit=Any_Expand_PHR, short=PHR, post_period_start=2019);
%step1_flag(benefit=Any_SSBCI, short=SSBCI, post_period_start=2020);
%step1_flag(benefit=InHomeSupportServ, short=IHSS, post_period_start=2019);
%step1_flag(benefit=FoodSecurity, short=FS, post_period_start=2020);
%step1_flag(benefit=HousingQuality, short=HQ, post_period_start=2020);
%step1_flag(benefit=IndoorAirQuality, short=IAQ, post_period_start=2020);

*%step1_flag(benefit=GeneralSupportsforLiving, short=GS, post_period_start=2020);
*%step1_flag(benefit=Any_PHR_SSBCI, short=PHRSS, post_period_start=2019);
*%step1_flag(benefit=Meal, short=ML, post_period_start=2019);
*%step1_flag(benefit=Transportation, short=MT, post_period_start=2019);
*%step1_flag(benefit=TransportationNonMedical, short=NMT, post_period_start=2020);



/**************************************************************
/* Step 2: Assign relative time (time_rel) for event study DiD
*		   - For trt=1: time_l = year - adopt_year 
*			 (0 for adoption year, negative pre, positive post).
*		   - For control=1: time_rel = 0 always.
/**************************************************************/
%macro step2_time(benefit=, short=);
    data &short._flag_time;
        set &short._did_flag;
        if trt_&short. = 1 then time_l_&short. = year - plan_adopt_year_&short.;
        else time_l_&short. = 0;
		label time_l_&short. = "Time Indicator: count of years from benefit offering; 0 for adoption/control";
    run;

    /* Count N for each time_l for treatment */
	title "&short. - N by time_l for Treatment";
    proc freq data=&short._flag_time;
        where trt_&short. = 1;
        tables time_l_&short. / nocum nopercent missing;
    run;

    /* Count N for control */
	title "&short. - N for Control";
    proc freq data=&short._flag_time;
        where trt_&short. = 0;
        tables time_l_&short. / nocum nopercent missing;
    run;
    title;
    
%mend step2_time;

%step2_time(benefit=Any_Expand_PHR, short=PHR);
%step2_time(benefit=Any_SSBCI, short=SSBCI);
%step2_time(benefit=FoodSecurity, short=FS);
%step2_time(benefit=HousingQuality, short=HQ);
%step2_time(benefit=IndoorAirQuality, short=IAQ);
%step2_time(benefit=InHomeSupportServ, short=IHSS);

*%step2_time(benefit=GeneralSupportsforLiving, short=GS);
*%step2_time(benefit=Any_PHR_SSBCI, short=PHRSS);
*%step2_time(benefit=Meal, short=ML);
*%step2_time(benefit=Transportation, short=MT);
*%step2_time(benefit=TransportationNonMedical, short=NMT);


/**************************************************************
* Step 3: Create a county-level indicator that has at least one plan with the benefit 
**************************************************************/
%macro step3_county(benefit=, short=);
  proc sql;
	  create table &short._county as
	  select year,
	         county_SSA,
	         max(coalesce(&benefit.,0)) as county_has_&short. 
	  from &short._flag_time
	  group by year, county_SSA;

	  create table did_&short. as
	  select a.*,
	         coalesce(b.county_has_&short., 0) as county_&short. 
               label="County has plan with &benefit. (year-specific)"
	    from &short._flag_time a
	    left join &short._county b
	    on a.year = b.year and a.county_SSA= b.county_SSA;
  quit;
%mend step3_county;

%step3_county(benefit=Any_Expand_PHR, short=PHR);
%step3_county(benefit=Any_SSBCI, short=SSBCI);
%step3_county(benefit=InHomeSupportServ, short=IHSS);
%step3_county(benefit=FoodSecurity, short=FS);
%step3_county(benefit=HousingQuality, short=HQ);
%step3_county(benefit=IndoorAirQuality, short=IAQ);

*%step3_county(benefit=GeneralSupportsforliving, short=GS);
*%step3_county(benefit=Any_PHR_SSBCI, short=PHRSS);
*%step3_county(benefit=Transportation, short=MT);
*%step3_county(benefit=Meal, short=ML);
*%step3_county(benefit=TransportationNonMedical, short=NMT);






