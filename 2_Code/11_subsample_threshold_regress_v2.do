clear
cd "/Users/antonianaujoks/Documents/Stata"
use "WB_ESG_panel_final.dta", clear

xtset id year   // before deleting NA, balanced panel as data

* deleting rows with missing values in key variables
drop if missing(energy_intensity) | missing(electricity_production) | missing(reshare) | ///
        missing(co2) | missing(government_effectiveness) | missing(income)

xtset id year   // panel may become unbalanced after deletion

tab year

drop if year==2000   // because 2001 is missing; restrict scope to 2002–2020

* Rebalance panel to 2002–2020 (requires xtbalance installed)
* If you get "command xtbalance not found", run: ssc install xtbalance
xtbalance, range(2002 2020)

xtset id year   // verify panel structure

summarize co2 reshare energy_intensity electricity_production government_effectiveness

* log transforms (avoid ln(0) with small constants where needed)
gen ln_co2 = ln(co2)
gen ln_energy_intensity = ln(energy_intensity)
gen ln_reshare = ln(reshare + 0.001)
gen ln_electricity_production = ln(electricity_production + 0.001)

misstable summarize co2 reshare energy_intensity electricity_production government_effectiveness

*=======================================
* Build income-group indicators used earlier
*=======================================

decode income, gen(income_group_label)
gen income_group_label_lc = lower(trim(income_group_label))

* Group 1: Low income + Lower middle income
gen byte low_lowermid = ///
    strpos(income_group_label_lc, "low income") > 0 | ///
    strpos(income_group_label_lc, "lower middle income") > 0

* Group 2: Upper middle income + High income
gen byte uppermid_high = ///
    strpos(income_group_label_lc, "upper middle income") > 0 | ///
    strpos(income_group_label_lc, "high income") > 0

*=======================================
* Threshold regression by income group
*=======================================

* NOTE: xthreg is user-written. If you get "command xthreg not found",
* install it (if available in your setup) e.g. via: ssc install xthreg

* Group 1 regression: Low income + Lower middle income
xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness ///
    if low_lowermid == 1, ///
    rx(ln_reshare) qx(ln_reshare) thnum(1) trim(0.01) grid(400) bs(300)

estimates store thr_llm_1

xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness ///
    if low_lowermid == 1, ///
    rx(ln_reshare) qx(ln_reshare) thnum(2) trim(0.01 0.01) grid(400) bs(300 300)

estimates store thr_llm_2

xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness ///
    if low_lowermid == 1, ///
    rx(ln_reshare) qx(ln_reshare) thnum(3) trim(0.01 0.01 0.01) grid(400) bs(300 300 300)

estimates store thr_llm_3

* Group 1 triple-threshold LR statistic graphs
_matplot e(LR21), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(a) First Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_low_triple_1, replace) nodraw

_matplot e(LR22), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(b) Second Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_low_triple_2, replace) nodraw

_matplot e(LR3), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(c) Third Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_low_triple_3, replace) nodraw

graph combine LR_low_triple_1 LR_low_triple_2 LR_low_triple_3, ///
    cols(1) rows(3) ///
    title("Triple Threshold LR Statistics (Low + Lower-middle)", size(medsmall) color(black)) ///
    note("Note: Dashed line indicates 95% critical value (7.35).", size(vsmall) color(gs8)) ///
    graphregion(color(white)) ///
    xsize(12) ysize(20)

graph export "LR_triple_threshold_low_lowermid.png", replace width(2400)

* Group 2 regression: Upper middle income + High income
xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness ///
    if uppermid_high == 1, ///
    rx(ln_reshare) qx(ln_reshare) thnum(1) trim(0.01) grid(400) bs(300)

estimates store thr_umh_1

xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness ///
    if uppermid_high == 1, ///
    rx(ln_reshare) qx(ln_reshare) thnum(2) trim(0.01 0.01) grid(400) bs(300 300)

estimates store thr_umh_2

xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness ///
    if uppermid_high == 1, ///
    rx(ln_reshare) qx(ln_reshare) thnum(3) trim(0.01 0.01 0.01) grid(400) bs(300 300 300)

estimates store thr_umh_3

* Group 2 triple-threshold LR statistic graphs
_matplot e(LR21), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(a) First Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_high_triple_1, replace) nodraw

_matplot e(LR22), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(b) Second Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_high_triple_2, replace) nodraw

_matplot e(LR3), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(c) Third Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_high_triple_3, replace) nodraw

graph combine LR_high_triple_1 LR_high_triple_2 LR_high_triple_3, ///
    cols(1) rows(3) ///
    title("Triple Threshold LR Statistics (Upper-middle + High)", size(medsmall) color(black)) ///
    note("Note: Dashed line indicates 95% critical value (7.35).", size(vsmall) color(gs8)) ///
    graphregion(color(white)) ///
    xsize(12) ysize(20)

graph export "LR_triple_threshold_uppermid_high.png", replace width(2400)

* Compare the two income-group regressions (requires esttab/estout)
* If you get "command esttab not found", run: ssc install estout, replace
esttab thr_llm_1 thr_umh_1 ///
    using "threshold_income_groups_comparison.rtf", ///
    b(3) se(3) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    title("Table: Panel Fixed-Effects Threshold Regression by Income Group") ///
    mtitle("Low + Lower-middle" "Upper-middle + High") ///
    nobaselevels ///
    scalars("N Observations" "r2_w Within R-sq" "r2_o Overall R-sq") ///
    note("Standard errors in parentheses. * p<0.1, ** p<0.05, *** p<0.01." ///
         "All models include country and year fixed effects." ///
         "Threshold variable: ln(REShare + 0.001).") ///
    replace

ereturn list
