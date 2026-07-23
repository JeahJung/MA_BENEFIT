***************************************************************************
* Program name: 1.1 Create base analytic data.sas    
* Purpose: Use 20% cSNPs and 20% conventional MA plans data, add following variables: 
*             1) SNP type indicators
*             2) Enrollment at plan level
*             3) Benefit indicators (medical transportation, meals on a limited basis, 
*                each expanded PHR benefit indicator, SSBCI category indicators)
*             4) Years of MA experience
*             5) Less than 5 years of MA experience indicator 
*             6) New plan started in 2019 or after indicator
*             7) Plan characteristic variables (plan type, org type, plan name, org name, etc) 
*			  8) Community dwelling indicator for long-term (>100 days) nursing home stayers 
*             9) HCC tertile and frailty tertile
* Input file: csnp.analytic_control.sas7bdat
*             itt.master_plan_benefit.sas7bdat
*             ASSMNT.MDS_ASMT3_20XX;
* Output file: itt.base_all.sas7bdat;
***************************************************************************;

libname itt "&myfiles_root./dua_&dua./SAS/Benefit_ITT/Data_Files" compress=yes;
libname csnp "&myfiles_root./dua_&dua./CSNP/Data_Files" compress=yes;


/*****************************************************************************************************
/* Step 1: Clean itt.anal_all data to exclude DEMO, PACE, EGWP, COST plans and clean csnp.analytic_control data
/*****************************************************************************************************/

proc contents data=itt.master_plan_benefit varnum;
run;

data base_all;
set itt.master_plan_benefit;
if find(Medicare_Plan_Type, "Cost", "i") > 0 then delete;
if substr(plan_id, 1, 1) = '8' then delete;
if org_type_num not in ('01', '02', '04', '11') then delete;
if plan_type_num not in ('01', '02', '04', '05', '07', '09', '29', '31') then delete;
run;


data anal_control;
    set csnp.analytic_control;
	if white = . then white = 0;
	if black = . then black = 0;
	if asian = . then asian = 0;
	if hispanic = . then hispanic = 0;
	if ED_ind = . then ED_ind = 0;
	if IP_ind = . then IP_ind = 0;
	rename EOY_PTC_CNTRCT_ID = contract_id
           EOY_PTC_PBP_ID = plan_id;
run;


/*****************************************************************************************************
/* Step 2: Add variables to the cleaned master file
/*****************************************************************************************************/

proc sql;
  create table plan_benefit as
  select a.*, 
  		 b.SNP,
		 b.C_SNP,
		 b.D_SNP,
		 b.I_SNP,
		 b.HIDE,
		 b.FIDE,
		 b.CO,
         b.Transportation,
		 b.Meal,
		 b.AnnualRoutinePhysical,
         b.HealthEducation,
         b.NutritionalDietary,
         b.SmokingCessationCounsel,
         b.FitnessBenefit,
         b.EnhancedDiseaseMngt,
         b.Telemonitoring,
         b.RemoteAccessTech,
         b.HomeBathroomSafeDev,
         b.Counseling,
         b.InHomeSafeAssess,
         b.PersonalEmergencyResp,
         b.MedicalNutritionTherapy,
         b.PostdischargeInHomeMed,
         b.ReadmissionPrevention,
         b.WigsHairLoss,
         b.WeightManagementProg,
         b.AlternativeTherapies,
         b.TherapeuticMassage,
         b.AdultDayHealthServ,
         b.HomeBasedPalliative,
         b.InHomeSupportServ,
         b.SupportCaregiversEnroll, 
		 b.Any_Expand_PHR,
		 b.FoodProduce,
         b.Meal_BeyondLimit,
		 b.FoodSecurity,
         b.PestControl,
         b.IndoorAirQuality,
		 b.HousingQuality,
		 b.StructuralHomeModifcation,
		 b.SocialNeedsBenefit,
         b.ComplementaryTherapies,
         b.SelfDirectingServices,
		 b.GeneralSupportsforliving,
		 b.TransportationNonMedical,
	     b.Any_SSBCI,
		 b.plan_type_num,
		 b.org_type_num,
		 b.org_type,
		 b.plan_type,
		 b.org_name,
		 b.org_market_name,
		 b.plan_name,
		 b.parent_org,
		 b.enrollment,
		 b.plan_years,
         b.plan_less_5years,
		 b.plan_starting_2019
		from anal_control a 
		left join base_all b
		on a.contract_id=b.contract_id and a.plan_id=b.plan_id and a.year=b.year;
quit;


/************************************************************************************
/* Step 3: Create long_term_nh_stayer indicator for each year of 2017-2022 
/***********************************************************************************/
%macro mds;
	%do y=2017 %to 2022;

	/************************************************************************************
	/* Select distinct beneficiaries for the current year
	/***********************************************************************************/
	proc sql;
		create table bene_&y. as
		select distinct BENE_ID,
					    year
		from plan_benefit
		where year=&y.;
  	quit;

	/************************************************************************************
	/* Identifies beneficiaries who had at least one nursing home stay longer than 100 days
    /* in the current year
	/***********************************************************************************/
	proc sql;
    	create table cd_&y. as
    	select a.BENE_ID,
               a.year,
               max(case when (b.TRGT_DT - b.A1600_ENTRY_DT) > 100 then 1
                        else 0
                   end) as long_term_nh_stayer
    	from bene_&y. a
    	left join ASSMNT.MDS_ASMT3_&y. b
    	on a.bene_id = b.bene_id
      	group by a.BENE_ID, a.year;
    quit;

	/************************************************************************************
	/* Merge long_term_nh_stayer indicator back to anal_plan_benefit
	/***********************************************************************************/
	proc sql;
		create table base_&y. as
		select a.*,
               b.long_term_nh_stayer label "Long-term (>100 days) nursing home stayers"
		from plan_benefit a
		left join cd_&y. b
		on a.bene_id=b.bene_id
		where a.year=&y.;
	quit;

	proc freq data=base_&y.;
	tables long_term_nh_stayer / missing;
	run;

	%end;
%mend mds; options mlogic mprint;
%mds;

/* Append all years base data */
data base_all;
set base_2017-base_2022;
array b {*}  SNP C_SNP D_SNP I_SNP
             Transportation
		     Meal
		     AnnualRoutinePhysical
	         HealthEducation
	         NutritionalDietary
	         SmokingCessationCounsel
	         FitnessBenefit
	         EnhancedDiseaseMngt
	         Telemonitoring
	         RemoteAccessTech
	         HomeBathroomSafeDev
	         Counseling
	         InHomeSafeAssess
	         PersonalEmergencyResp
	         MedicalNutritionTherapy
	         PostdischargeInHomeMed
	         ReadmissionPrevention
	         WigsHairLoss
	         WeightManagementProg
	         AlternativeTherapies
	         TherapeuticMassage
	         AdultDayHealthServ
	         HomeBasedPalliative
	         InHomeSupportServ
	         SupportCaregiversEnroll
		     Any_Expand_PHR
		     FoodProduce
             Meal_BeyondLimit
		     FoodSecurity
         	 PestControl
         	 IndoorAirQuality
		 	 HousingQuality
		 	 StructuralHomeModifcation
		 	 SocialNeedsBenefit
         	 ComplementaryTherapies
         	 SelfDirectingServices
		 	 GeneralSupportsforliving
		 	 TransportationNonMedical
	     	 Any_SSBCI;

  do i=1 to dim(b);
    if b[i] = . then b[i] = 0;
  end;
  drop i;

if SNP ne 1 then conventional_MA = 1; else conventional_MA = 0;
run;


/**************************************************************
* Step 4: Add tertile variables for HCC_score and frailty_score
**************************************************************/
proc sort data=base_all;
by year;
run;

/* Rank HCC_score into tertiles (descending) */
proc rank data=base_all out=temp_hcc groups=3 descending;
by year;
var HCC_score;
ranks hcc_rank;
run;

/* Rank frailty_score into tertiles (descending) */
proc rank data=temp_hcc out=temp_frailty groups=3 descending;
by year;
var frailty_score;
ranks frailty_rank;
run;

/* Create final tertiles (1�3) */
data itt.base_all;
  set temp_frailty;
  hcc_tertile = hcc_rank + 1;
  frailty_tertile = frailty_rank + 1;
  label hcc_tertile = "HCC Score Tertile (1=highest, 3=lowest)"
        frailty_tertile = "Frailty Score Tertile (1=highest, 3=lowest)";
  drop hcc_rank frailty_rank;
run;






