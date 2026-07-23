/* Export to STATA */
/* Count total obs */
proc sql noprint;
    select count(*) into :nobs
    from ittrev.did_anal_stayer;
quit;

data did_anal_stayer_part1;
    set ittrev.did_anal_stayer(obs=%sysevalf(&nobs/4, floor));
run;
data did_anal_stayer_part2;
    set ittrev.did_anal_stayer(
        firstobs=%eval(%sysevalf(&nobs/4, floor)+1)
        obs=%sysevalf(&nobs/2, floor)
    );
run;
data did_anal_stayer_part3;
    set ittrev.did_anal_stayer(
        firstobs=%eval(%sysevalf(&nobs/2, floor)+1)
        obs=%sysevalf(&nobs*3/4, floor)
    );
run;
data did_anal_stayer_part4;
    set ittrev.did_anal_stayer(
        firstobs=%eval(%sysevalf(&nobs*3/4, floor)+1)
    );
run;

/* Export each part */
proc export data=did_anal_stayer_part1
    outfile="&myfiles_root./dua_&dua./Stata/Benefit_ITT_Revise/did_anal_stayer_part1.dta"
    replace;
run;

proc export data=did_anal_stayer_part2
    outfile="&myfiles_root./dua_&dua./Stata/Benefit_ITT_Revise/did_anal_stayer_part2.dta"
    replace;
run;

proc export data=did_anal_stayer_part3
    outfile="&myfiles_root./dua_&dua./Stata/Benefit_ITT_Revise/did_anal_stayer_part3.dta"
    replace;
run;

proc export data=did_anal_stayer_part4
    outfile="&myfiles_root./dua_&dua./Stata/Benefit_ITT_Revise/did_anal_stayer_part4.dta"
    replace;
run;
