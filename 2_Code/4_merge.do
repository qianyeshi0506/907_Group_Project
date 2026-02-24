/*===========================================================================
Project:  907 Group Project
Script:   4_merge.do
Purpose:  Merge income group classification into cleaned ESG panel
Input:    WB_ESG_panel_cleaned.dta, WB_income_group.dta
Output:   WB_ESG_panel_final.dta
===========================================================================*/

clear all
set more off

*---------------------------------------------------------------------------
* Step 1: load main data set (ESG panel)
*---------------------------------------------------------------------------
use "F:\\Onedrive映射\\1kcl\\ESG\\7QQMM907\\907_Group_Project\\1_Data\\2_Processed\\WB_ESG_panel_cleaned.dta", clear

*---------------------------------------------------------------------------
* Step 2: merge and include grouping data
* many-to-one：each country in ESG panel includes multiple years, however only one row for each country in "income group"
*---------------------------------------------------------------------------
merge m:1 country_code using"F:\\Onedrive映射\\1kcl\\ESG\\7QQMM907\\907_Group_Project\\1_Data\\2_Processed\\WB_income_group.dta"

*---------------------------------------------------------------------------
* Step 3: check merging result
*---------------------------------------------------------------------------
* _merge == 1：only exist in ESG panel, no corresponding income group
* _merge == 2：only exist in income group, no corresponding ESG panel
* _merge == 3：successful match

tab _merge

* check unmatched country (_merge == 1, may be region World or Euro Area)
list country_name country_code if _merge == 1, clean noobs

* check redundant country in income group (_merge == 2)
list country_code if _merge == 2, clean noobs

*---------------------------------------------------------------------------
* Step 4: manage unmatched observation
*  _merge==2 is usualy a country in income group but not in ESG panel, can be deleted
*---------------------------------------------------------------------------
drop if _merge == 2

* delete merge indicator variable
drop _merge

*---------------------------------------------------------------------------
* Step 5: varify merging result
*---------------------------------------------------------------------------
* check income variable distribution
tab income

* check income coding definition（High/Low/Lower-middle/Upper-middle）
label list income

* check if any country is missing income group
count if missing(income)
list country_name country_code if missing(income), clean noobs

*---------------------------------------------------------------------------
* Step 6: state panel structure and save file
*---------------------------------------------------------------------------
xtset id year

order country_name country_code id year income
sort id year

save "F:\\Onedrive映射\\1kcl\\ESG\\7QQMM907\\907_Group_Project\\1_Data\\2_Processed\\WB_ESG_panel_final.dta", replace

di "Merge finished! Total " _N " pbservations"
describe
