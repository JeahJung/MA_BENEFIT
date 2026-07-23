***************************************************************************
* Program name: 3.1 Create final DiD analysis data.sas    
* Purpose: Create cleaned overall data that
*          1. Drop ESRD=1
*          2. Limit to at least 12 conditions 
*          3. Drop missing covariates.
*          4. Drop long term nursing home styaer.
*          Then export to STATA for regression
* Input file: base_clean.sas7bdat
*             itt.did_&short..sas7bdat;
* Output file: did_all
*              itt.did_anal;
***************************************************************************;

libname itt "&myfiles_root./dua_&dua./SAS/Benefit_ITT/Data_Files" compress=yes;
libname ittrev "&myfiles_root./dua_&dua./SAS/Benefit_ITT_Revise/Data_Files" compress=yes;

/* Merge each benefit data to one data */
proc sql;
	create table did_anal as
	select a.*,
	       b.stay_same_plan_ctrl_FS,
		   c.stay_same_plan_ctrl_HQ,
		   d.stay_same_plan_ctrl_SSBCI,
		   e.stay_same_plan_ctrl_PHR,
		   f.stay_same_plan_ctrl_IHSS
	from itt.did_anal_stayer a
	left join did_FS b 
		on a.bene_id=b.bene_id and a.contract_plan_id=b.contract_plan_id and a.year=b.year
	left join did_HQ c 
		on a.bene_id=c.bene_id and a.contract_plan_id=c.contract_plan_id and a.year=c.year
	left join did_SSBCI d 
		on a.bene_id=d.bene_id and a.contract_plan_id=d.contract_plan_id and a.year=d.year
    left join did_PHR e 
		on a.bene_id=e.bene_id and a.contract_plan_id=e.contract_plan_id and a.year=e.year
	left join did_IHSS f 
		on a.bene_id=f.bene_id and a.contract_plan_id=f.contract_plan_id and a.year=f.year;
quit;

data ittrev.did_anal_stayer;
set did_anal;
run;

