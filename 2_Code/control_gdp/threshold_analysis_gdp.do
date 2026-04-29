/*==============================================================
  threshold_analysis.do
  
  Purpose : Import merged GDP–ESG panel, clean data, construct
            a balanced panel, and estimate Hansen (1999) fixed-
            effect panel threshold models.
  
  Dependent variable : ln(CO2)
  Threshold variable : reshare  (renewable energy share)
  Regime-dependent   : ln(reshare)
  
  Author  : [Your Name]
  Date    : 2026-03-17
==============================================================*/

clear all
set more off

cd "F:\Onedrive映射\1kcl\ESG\7QQMM907\DATA\Results"

use "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\2_Processed\WB_ESG_panel_merged_GDP.dta", clear


* =============================================================
* 1. Variable naming
* =============================================================

capture rename government_effectivenes government_effectiveness


* =============================================================
* 2. Remove duplicates introduced by merge
* =============================================================

* Keep only matched observations (master ∩ using)
capture tab _merge
capture keep if _merge == 3
capture drop _merge

* Diagnose duplicates on panel identifiers
duplicates report id year
duplicates list id year in 1/20

* Drop exact duplicates, keeping the first occurrence
duplicates drop id year, force


* =============================================================
* 3. Data cleaning & panel balancing
* =============================================================

xtset id year                          // verify panel structure

* Drop observations with missing values in any key variable
drop if missing(energy_intensity, electricity_production, reshare, ///
    co2, government_effectiveness, income, gdp)

xtset id year                          // check structure after deletion

tab year

* Year 2001 has no observations; drop 2000 to set scope to 2002–2020
drop if year == 2000

* Force a strictly balanced panel over 2002–2020
xtbalance, range(2002 2020)

xtset id year                          // confirm balanced panel
xtdes


* =============================================================
* 4. Generate log-transformed variables
* =============================================================

gen ln_co2                    = ln(co2)
gen ln_energy_intensity       = ln(energy_intensity)
gen ln_reshare                = ln(reshare + 0.001)
gen ln_electricity_production = ln(electricity_production + 0.001)
gen ln_gdp                    = ln(gdp)

label variable ln_co2                    "ln(CO2)"
label variable ln_energy_intensity       "ln(Energy Intensity)"
label variable ln_reshare                "ln(RE Share + 0.001)"
label variable ln_electricity_production "ln(Electricity Production + 0.001)"
label variable ln_gdp                    "ln(GDP, current US$)"

* Descriptive statistics
summarize co2 reshare energy_intensity electricity_production ///
    government_effectiveness gdp

* Confirm no remaining missings in regression variables
misstable summarize ln_co2 ln_reshare ln_energy_intensity ///
    ln_electricity_production government_effectiveness ln_gdp


* =============================================================
* 5. Year dummies (for robustness checks with time fixed effects)
* =============================================================

tab year, gen(yr_)


* =============================================================
* 6. Panel threshold regressions (Hansen 1999)
* =============================================================

* ----- 6.1  Single threshold: H0 (linear) vs H1 (1 threshold) -----

xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness ln_gdp, ///
    rx(ln_reshare) qx(reshare) thnum(1) trim(0.01) grid(400) bs(300)


* ----- 6.2  Double threshold: H1 (1 threshold) vs H2 (2 thresholds) -----

xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness ln_gdp, ///
    rx(ln_reshare) qx(reshare) thnum(2) ///
    trim(0.01 0.01) grid(400) bs(300 300)


* ----- 6.3  Double threshold with year dummies (robustness) -----

xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness ln_gdp yr_2 - yr_19, ///
    rx(ln_reshare) qx(reshare) thnum(2) ///
    trim(0.01 0.01) grid(400) bs(300 300)


* ----- 6.4  Triple threshold: H2 (2 thresholds) vs H3 (3 thresholds) -----

xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness ln_gdp, ///
    rx(ln_reshare) qx(reshare) thnum(3) ///
    trim(0.01 0.01 0.01) grid(400) bs(300 300 300)


* ----- 6.5  Triple threshold with year dummies (robustness) -----

xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness ln_gdp yr_2 - yr_19, ///
    rx(ln_reshare) qx(reshare) thnum(3) ///
    trim(0.01 0.01 0.01) grid(400) bs(300 300 300)

* Joint significance test for year dummies
testparm yr_2 - yr_19


* =============================================================
* 7. Likelihood-ratio plots for the double-threshold model
* =============================================================

* --- (a) First threshold LR curve ---

_matplot e(LR21), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(a) First Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_double_1, replace) nodraw

* --- (b) Second threshold LR curve ---

_matplot e(LR22), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(b) Second Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_double_2, replace) nodraw

* --- Combined panel ---

graph combine LR_double_1 LR_double_2, ///
    cols(1) rows(2) ///
    title("Double Threshold LR Statistics", ///
          size(medsmall) color(black)) ///
    note("Note: Dashed line indicates 95% critical value (7.35).", ///
         size(vsmall) color(gs8)) ///
    graphregion(color(white)) ///
    xsize(12) ysize(20)

graph export "LR_double_threshold.png", replace width(2400)

di as txt "=== Analysis complete ==="
