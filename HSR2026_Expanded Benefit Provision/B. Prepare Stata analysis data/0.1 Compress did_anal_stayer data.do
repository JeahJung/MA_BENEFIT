cd "/home/gso275/files/dua_&dua./Stata/Benefit_ITT_Revise"
capture log close
log using "0.1 Compress did_anal_stayer data 3-16-2025.log", replace
**********************************************************************************
* Purpose: Compress did_anal_stayer_partX data
* Input file: did_anal_stayer_part1
*             did_anal_stayer_part2
*             did_anal_stayer_part3
*             did_anal_stayer_part4
* Output file: did_anal_stayer 
* Note: Data did_anal_stayer_part1, did_anal_stayer_part2, did_anal_stayer_part3 and did_anal_stayer_part4 were exported from SAS
********************************************************************************** 

use "did_anal_stayer_part1", clear
compress
save "did_anal_stayer_part1", replace
count

use "did_anal_stayer_part2", clear
compress
save "did_anal_stayer_part2", replace
count

use "did_anal_stayer_part3", clear
compress
save "did_anal_stayer_part3", replace
count

use "did_anal_stayer_part4", clear
compress
save "did_anal_stayer_part4", replace
count

use "did_anal_stayer_part1", clear
append using "did_anal_stayer_part2" "did_anal_stayer_part3" "did_anal_stayer_part4"
save "did_anal_stayer", replace
count



log close
