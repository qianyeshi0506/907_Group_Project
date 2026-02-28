/*===========================================================================
Project:  907 Group Project
Script:   8_subsample_analysis.do
Purpose:  Sub-sample FE analysis by income level groups
Input:    WB_ESG_panel_final.dta
Output:   subsample_income_fe.rtf
===========================================================================*/

clear all
set more off

* Set working directory (update this path for your environment)
cd "/Users/antonianaujoks/Documents/Stata"

* Load panel data
use "WB_ESG_panel_final.dta", clear

* Harmonize governance variable name
capture rename government_effectivenes government_effectiveness

* Keep complete observations in key variables
drop if missing(energy_intensity) | missing(electricity_production) | missing(reshare) | ///
        missing(co2) | missing(government_effectiveness) | missing(income)

* Restrict to the balanced analysis window
drop if year == 2000
xtset id year
xtbalance, range(2002 2020)
xtset id year

* Log transforms
gen ln_co2 = ln(co2)
gen ln_reshare = ln(reshare + 0.001)
gen ln_energy_intensity = ln(energy_intensity)
gen ln_electricity_production = ln(electricity_production + 0.001)

* Decode income labels so grouping is robust to numeric coding
decode income, gen(income_group_label)
gen income_group_label_lc = lower(trim(income_group_label))

* Sub-sample indicators
* Group 1: Low income + Lower middle income
gen byte low_lowermid = ///
    strpos(income_group_label_lc, "low income") > 0 | ///
    strpos(income_group_label_lc, "lower middle income") > 0

* Group 2: Upper middle income + High income
gen byte uppermid_high = ///
    strpos(income_group_label_lc, "upper middle income") > 0 | ///
    strpos(income_group_label_lc, "high income") > 0

* Sanity checks
count if low_lowermid == 1
count if uppermid_high == 1
count if low_lowermid == 1 & uppermid_high == 1

*=========================================
* Sub-sample FE regressions
*=========================================

* Group 1: Low + Lower-middle income
xtreg ln_co2 ln_reshare ln_energy_intensity ln_electricity_production ///
    government_effectiveness i.year if low_lowermid == 1, ///
    fe vce(cluster id)
estimates store fe_low_lowermid

* Group 2: Upper-middle + High income
xtreg ln_co2 ln_reshare ln_energy_intensity ln_electricity_production ///
    government_effectiveness i.year if uppermid_high == 1, ///
    fe vce(cluster id)
estimates store fe_upmid_high

* Export comparison table (requires esttab/estout)
esttab fe_low_lowermid fe_upmid_high ///
    using "subsample_income_fe.rtf", ///
    b(3) se(3) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    title("Sub-sample FE Results by Income Group") ///
    mtitle("Low + Lower-middle" "Upper-middle + High") ///
    label ///
    scalars("N Observations" "r2_w Within R-sq" "r2_o Overall R-sq") ///
    note("Clustered standard errors at country level." ///
         "All models include country and year fixed effects." ///
         "Dependent variable: ln(CO2).") ///
    replace

* Optional pooled specification with slope heterogeneity on ln_reshare
xtreg ln_co2 c.ln_reshare##i.uppermid_high ln_energy_intensity ///
    ln_electricity_production government_effectiveness i.year, ///
    fe vce(cluster id)
estimates store fe_interaction
