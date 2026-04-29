/*===========================================================================
Project:  907 Group Project — ESG & Energy Transition Analysis
Script:   05_descriptive_stats.do
Purpose:  Generate descriptive statistics for all key variables
Script:   5_descriptive statistics.do
Purpose:  Generate descriptive statistics for two pre-defined income sub-samples
Input:    WB_ESG_panel_final.dta
Outputs:  descriptive_stats_by_income_sets.rtf
          correlation_matrix_by_income_sets.rtf
===========================================================================*/

clear all
set more off

*---------------------------------------------------------------------------
* Set working directory (Mac)
* Step 1: set working directory and load data set
*---------------------------------------------------------------------------
cd "/Users/antonianaujoks/Documents/Stata"

*---------------------------------------------------------------------------
* Step 1: load data set: ESG_final
*---------------------------------------------------------------------------
use "WB_ESG_panel_final.dta", clear

* Harmonize governance variable name if needed
capture rename government_effectivenes government_effectiveness

*---------------------------------------------------------------------------
* Step 2: state panel structure
*---------------------------------------------------------------------------
xtset id year
* Keep complete observations in key variables
keep if !missing(co2, reshare, electricity_production, energy_intensity, government_effectiveness, income)

*---------------------------------------------------------------------------
* Step 3: descriptive statistics for all samples 
* Step 2: build the same two income-group sets used in subsample analysis
*---------------------------------------------------------------------------
summarize co2 reshare electricity_production energy_intensity government_effectiveness income
summarize co2 reshare electricity_production energy_intensity government_effectiveness, detail
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

*---------------------------------------------------------------------------
* Step 4: descriptive statistics by income group
* Step 3: state panel structure and check sub-sample sizes
*---------------------------------------------------------------------------
bysort income: summarize co2 reshare electricity_production energy_intensity government_effectiveness
xtset id year
count if low_lowermid == 1
count if uppermid_high == 1
count if low_lowermid == 1 & uppermid_high == 1

*---------------------------------------------------------------------------
* Step 5: export formatted descriptive statistics table
* Step 4: variable labels for formatted output
*---------------------------------------------------------------------------
* If needed: ssc install estout, replace

label variable co2                      "CO2 Emissions (metric tons per capita)"
label variable reshare                  "Renewable Energy Share (% of total)"
label variable electricity_production   "Electricity from Coal (% of total)"
label variable energy_intensity         "Energy Intensity (MJ/$2017 PPP GDP)"
label variable government_effectiveness "Government Effectiveness (WGI Estimate)"
label variable income                   "Income Group"

estpost summarize co2 reshare electricity_production energy_intensity government_effectiveness

esttab using "descriptive_stats.rtf", ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    label title("Table 1: Descriptive Statistics") ///
    collabels("Mean" "Std. Dev." "Min" "Max" "Obs") ///
    nonum replace

*---------------------------------------------------------------------------
* Step 6: variable correlation matrix
*---------------------------------------------------------------------------
pwcorr co2 reshare electricity_production energy_intensity government_effectiveness, star(0.05)

estpost correlate co2 reshare electricity_production energy_intensity government_effectiveness, matrix listwise
esttab using "correlation_matrix.rtf", ///
    not nostar unstack noobs compress replace ///
    title("Table 2: Correlation Matrix")

*---------------------------------------------------------------------------
* Step 7: panel data basic characteristics
*---------------------------------------------------------------------------
xtdescribe

tabstat co2 reshare electricity_production energy_intensity government_effectiveness, ///
    by(year) stats(mean) format(%9.3f)

tabstat co2 reshare electricity_production energy_intensity government_effectiveness, ///
    by(income) stats(mean sd) format(%9.3f)

*---------------------------------------------------------------------------
* Step 8: visualisation - variable distribution and trends
*---------------------------------------------------------------------------
bysort year: egen mean_co2     = mean(co2)
bysort year: egen mean_reshare = mean(reshare)

preserve
collapse (mean) mean_co2 mean_reshare, by(year)
drop if mean_co2==. | mean_reshare==.

twoway ///
    (line mean_co2 year,     lcolor(cranberry) lwidth(medthick) lpattern(solid)) ///
    (line mean_reshare year, lcolor(navy)      lwidth(medthick) lpattern(dash) yaxis(2)), ///
    title("CO{subscript:2} Emissions vs Renewable Energy Share Over Time", ///
          size(medium) color(black)) ///
    ytitle("Mean CO{subscript:2} (metric tons per capita)", axis(1) size(small)) ///
    ytitle("Mean Renewable Energy Share (%)",               axis(2) size(small)) ///
    xtitle("Year", size(small)) ///
    xlabel(1990(5)2023, labsize(small) grid glcolor(gs14)) ///
    ylabel(, axis(1) labsize(small) grid glcolor(gs14)) ///
    ylabel(, axis(2) labsize(small)) ///
    legend(order(1 "CO{subscript:2} Emissions" 2 "Renewable Energy Share") ///
           position(6) rows(1) size(small) region(lwidth(none))) ///
    graphregion(color(white)) plotregion(color(white)) bgcolor(white) ///
    xsize(16) ysize(10)

graph export "trend_co2_reshare.png", replace width(2400)
restore

graph box co2, over(income, label(labsize(medsmall) angle(0))) ///
    box(1, color(gs10) lcolor(black) lwidth(thin)) ///
    box(2, color(gs10) lcolor(black) lwidth(thin)) ///
    box(3, color(gs10) lcolor(black) lwidth(thin)) ///
    box(4, color(gs10) lcolor(black) lwidth(thin)) ///
    medtype(cline, lcolor(black) lwidth(medthick) lpattern(dash)) ///
    nooutsides ///
    title("CO{subscript:2} Emissions by Income Group", ///
          size(medsmall) color(black) justification(center)) ///
    ytitle("CO{subscript:2} per Capita (metric tons)", size(small)) ///
    b1title("Income Group", size(small) color(black)) ///
    ylabel(0(5)25, labsize(small) nogrid) ///
    yscale(range(0 25)) ymtick(0(5)25) ///
    yline(7,  lcolor(black) lwidth(thin) lpattern(solid)) ///
    yline(20, lcolor(black) lwidth(thin) lpattern(dash)) ///
    graphregion(color(white) lwidth(none)) ///
    plotregion(color(white)  lcolor(none) margin(zero)) ///
    bgcolor(white) ///
    note("Note: Horizontal lines indicate global mean (solid) and" ///
         "high-income threshold (dashed).", ///
         size(vsmall) color(gs8)) ///
    xsize(14) ysize(10)

graph export "boxplot_co2_income.png", replace width(2400)

gen ln_co2 = ln(co2 + 0.01)

graph box ln_co2, over(income, label(labsize(medsmall) angle(0))) ///
    box(1, color(gs10) lcolor(black) lwidth(thin)) ///
    box(2, color(gs10) lcolor(black) lwidth(thin)) ///
    box(3, color(gs10) lcolor(black) lwidth(thin)) ///
    box(4, color(gs10) lcolor(black) lwidth(thin)) ///
    medtype(cline, lcolor(black) lwidth(medthick) lpattern(dash)) ///
    nooutsides ///
    title("ln(CO{subscript:2}) Emissions by Income Group", ///
          size(medsmall) color(black)) ///
    ytitle("ln(CO{subscript:2} per Capita)", size(small)) ///
    b1title("Income Group", size(small)) ///
    ylabel(, labsize(small) nogrid) ///
    graphregion(color(white) lwidth(none)) ///
    plotregion(color(white) lcolor(none) margin(zero)) ///
    bgcolor(white) ///
    note("Note: CO{subscript:2} in natural log scale.", ///
         size(vsmall) color(gs8)) ///
    xsize(14) ysize(10)

graph export "boxplot_lnco2_income.png", replace width(2400)

twoway ///
    (kdensity ln_co2 if income == 1, ///
        lcolor(black) lwidth(medthick) lpattern(solid)) ///
    (kdensity ln_co2 if income == 2, ///
        lcolor(gs5)   lwidth(medthick) lpattern(dash)) ///
    (kdensity ln_co2 if income == 3, ///
        lcolor(gs9)   lwidth(medthick) lpattern(shortdash)) ///
    (kdensity ln_co2 if income == 4, ///
        lcolor(gs12)  lwidth(medthick) lpattern(dot)), ///
    title("Distribution of ln(CO{subscript:2}) by Income Group", ///
          size(medsmall) color(black)) ///
    ytitle("Density", size(small)) ///
    xtitle("ln(CO{subscript:2} per Capita)", size(small)) ///
    xlabel(-5(1)4, labsize(small) nogrid) ///
    ylabel(, labsize(small) nogrid) ///
    xline(0, lcolor(gs10) lwidth(thin) lpattern(solid)) ///
    legend(order(1 "High Income" 2 "Low Income" ///
                 3 "Lower-Middle" 4 "Upper-Middle") ///
           position(1) ring(0) rows(4) ///
           size(small) region(lwidth(thin) lcolor(black))) ///
    graphregion(color(white) lwidth(none)) ///
    plotregion(color(white) lcolor(black) lwidth(thin) margin(small)) ///
    bgcolor(white) ///
    xsize(14) ysize(10) ///
    note("Note: CO{subscript:2} transformed to natural log scale." ///
         "Vertical line at ln(CO{subscript:2})=0 (i.e., 1 metric ton).", ///
         size(vsmall) color(gs8))

graph export "kdensity_lnco2_income.png", replace width(2400)bysort income: summarize co2 reshare electricity_production energy_intensity government_effectiveness

*---------------------------------------------------------------------------
* Step 5: export formated descriptive statistics table (exportable to Word/LaTeX)
*---------------------------------------------------------------------------

* install commend: ssc install estout, replace
*---------------------------------------------------------------------------
* add variable lebal, to show meaningful name in tables
*---------------------------------------------------------------------------
*change label
label variable co2                    "CO2 Emissions (metric tons per capita)"
label variable reshare                "Renewable Energy Share (% of total)"
label variable electricity_production "Electricity from Coal (% of total)"
label variable energy_intensity       "Energy Intensity (MJ/\$2017 PPP GDP)"
label variable government_effectiveness "Government Effectiveness (WGI Estimate)"
label variable income                 "Income Group"

estpost summarize co2 reshare electricity_production energy_intensity government_effectiveness

esttab using "descriptive_stats.rtf", cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") label title("Table 1: Descriptive Statistics") collabels("Mean" "Std. Dev." "Min" "Max" "Obs") nonum replace


*---------------------------------------------------------------------------
* Step 6: variable correlation matric 
* Step 5: descriptive statistics for each of the two income-group sets
*---------------------------------------------------------------------------
pwcorr co2 reshare electricity_production energy_intensity government_effectiveness, star(0.05)
eststo clear

* export correlation matric to word
estpost correlate co2 reshare electricity_production energy_intensity government_effectiveness, matrix listwise
estpost summarize co2 reshare electricity_production energy_intensity government_effectiveness ///
    if low_lowermid == 1
eststo desc_low_lowermid

esttab using "correlation_matrix.rtf", not nostar unstack noobs compress replace title("Table 2: Correlation Matrix")
estpost summarize co2 reshare electricity_production energy_intensity government_effectiveness ///
    if uppermid_high == 1
eststo desc_uppermid_high

*---------------------------------------------------------------------------
* Step 7: panel data basic characteristics 
*---------------------------------------------------------------------------
* view balance of panel
xtdescribe

* time dimension statistics
tabstat co2 reshare electricity_production energy_intensity government_effectiveness, by(year) stats(mean) format(%9.3f)

* coutry dimension statistics (as per income groups)
tabstat co2 reshare electricity_production energy_intensity government_effectiveness, by(income) stats(mean sd) format(%9.3f)

*---------------------------------------------------------------------------
* Step 8: visualisation - variable distribution and trends
*---------------------------------------------------------------------------
esttab desc_low_lowermid desc_uppermid_high ///
    using "descriptive_stats_by_income_sets.rtf", ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    collabels("Mean" "Std. Dev." "Min" "Max" "Obs") ///
    mtitle("Low + Lower-middle" "Upper-middle + High") ///
    title("Descriptive Statistics by Income-Group Set") ///
    label nonum replace

*---------------------------------------------------------------------------
* calculate mean change yearly
* Step 6: correlation matrices for each set (exported in one file)
*---------------------------------------------------------------------------
bysort year: egen mean_co2    = mean(co2)
bysort year: egen mean_reshare = mean(reshare)

* keep mean each year for plotting
preserve
collapse (mean) mean_co2 mean_reshare, by(year)
drop if mean_co2==. | mean_reshare==.

* plotting

twoway ///
    (line mean_co2 year,     lcolor(cranberry) lwidth(medthick) lpattern(solid)) ///
    (line mean_reshare year, lcolor(navy)      lwidth(medthick) lpattern(dash) yaxis(2)), ///
    ///
    title("CO{subscript:2} Emissions vs Renewable Energy Share Over Time", ///
          size(medium) color(black)) ///
    ///
    ytitle("Mean CO{subscript:2} (metric tons per capita)", axis(1) size(small)) ///
    ytitle("Mean Renewable Energy Share (%)",               axis(2) size(small)) ///
    xtitle("Year", size(small)) ///
    ///
    xlabel(1990(5)2023, labsize(small) grid glcolor(gs14)) ///
    ylabel(, axis(1) labsize(small) grid glcolor(gs14)) ///
    ylabel(, axis(2) labsize(small)) ///
    ///
    legend(order(1 "CO{subscript:2} Emissions" 2 "Renewable Energy Share") ///
           position(6) rows(1) size(small) region(lwidth(none))) ///
    ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    bgcolor(white) ///
    ///
    xsize(16) ysize(10)

graph export "trend_co2_reshare.png", replace width(2400)
restore

* boxplot for each income groups
*boxplot-CO2 absolute
graph box co2, over(income, ///
        label(labsize(medsmall) angle(0))) ///
    ///
    box(1, color(gs10) lcolor(black) lwidth(thin)) ///
    box(2, color(gs10) lcolor(black) lwidth(thin)) ///
    box(3, color(gs10) lcolor(black) lwidth(thin)) ///
    box(4, color(gs10) lcolor(black) lwidth(thin)) ///
    ///
    medtype(cline, lcolor(black) lwidth(medthick) lpattern(dash)) ///
    nooutsides ///
    ///
    title("CO{subscript:2} Emissions by Income Group", ///
          size(medsmall) color(black) justification(center)) ///
    ytitle("CO{subscript:2} per Capita (metric tons)", size(small)) ///
    b1title("Income Group", size(small) color(black)) ///
    ///
    ylabel(0(5)25, labsize(small) nogrid) ///
    yscale(range(0 25)) ///
    ymtick(0(5)25) ///
    ///
    yline(7,  lcolor(black) lwidth(thin) lpattern(solid)) ///
    yline(20, lcolor(black) lwidth(thin) lpattern(dash))  ///
    ///
    graphregion(color(white) lwidth(none)) ///
    plotregion(color(white)  lcolor(none) margin(zero)) ///
    bgcolor(white) ///
    ///
    note("Note: Horizontal lines indicate global mean (solid) and" ///
         "high-income threshold (dashed).", ///
         size(vsmall) color(gs8)) ///
    ///
    xsize(14) ysize(10)

graph export "boxplot_co2_income.png", replace width(2400)

*boxplot-CO₂ Ln
gen ln_co2 = ln(co2 + 0.01)   // add +0.01 to avoid ln(0) error

graph box ln_co2, over(income, label(labsize(medsmall) angle(0))) ///
    box(1, color(gs10) lcolor(black) lwidth(thin)) ///
    box(2, color(gs10) lcolor(black) lwidth(thin)) ///
    box(3, color(gs10) lcolor(black) lwidth(thin)) ///
    box(4, color(gs10) lcolor(black) lwidth(thin)) ///
    medtype(cline, lcolor(black) lwidth(medthick) lpattern(dash)) ///
    nooutsides ///
    title("ln(CO{subscript:2}) Emissions by Income Group", ///
          size(medsmall) color(black)) ///
    ytitle("ln(CO{subscript:2} per Capita)", size(small)) ///
    b1title("Income Group", size(small)) ///
    ylabel(, labsize(small) nogrid) ///
    graphregion(color(white) lwidth(none)) ///
    plotregion(color(white) lcolor(none) margin(zero)) ///
    bgcolor(white) ///
    note("Note: CO{subscript:2} in natural log scale.", ///
         size(vsmall) color(gs8)) ///
    xsize(14) ysize(10)

graph export "boxplot_lnco2_income.png", replace width(2400)

* kdensity-ln_co2
twoway ///
    (kdensity ln_co2 if income == 1, ///
        lcolor(black) lwidth(medthick) lpattern(solid)) ///
    (kdensity ln_co2 if income == 2, ///
        lcolor(gs5)   lwidth(medthick) lpattern(dash)) ///
    (kdensity ln_co2 if income == 3, ///
        lcolor(gs9)   lwidth(medthick) lpattern(shortdash)) ///
    (kdensity ln_co2 if income == 4, ///
        lcolor(gs12)  lwidth(medthick) lpattern(dot)), ///
    ///
    title("Distribution of ln(CO{subscript:2}) by Income Group", ///
          size(medsmall) color(black)) ///
    ytitle("Density", size(small)) ///
    xtitle("ln(CO{subscript:2} per Capita)", size(small)) ///
    ///
    xlabel(-5(1)4, labsize(small) nogrid) ///
    ylabel(, labsize(small) nogrid) ///
    ///
    xline(0, lcolor(gs10) lwidth(thin) lpattern(solid)) ///
    ///
    legend(order(1 "High Income" 2 "Low Income" ///
                 3 "Lower-Middle" 4 "Upper-Middle") ///
           position(1) ring(0) rows(4) ///
           size(small) region(lwidth(thin) lcolor(black))) ///
    ///
    graphregion(color(white) lwidth(none)) ///
    plotregion(color(white) lcolor(black) lwidth(thin) margin(small)) ///
    bgcolor(white) ///
    xsize(14) ysize(10) ///
    note("Note: CO{subscript:2} transformed to natural log scale." ///
         "Vertical line at ln(CO{subscript:2})=0 (i.e., 1 metric ton).", ///
         size(vsmall) color(gs8))

graph export "kdensity_lnco2_income.png", replace width(2400)
















eststo clear

estpost correlate co2 reshare electricity_production energy_intensity government_effectiveness ///
    if low_lowermid == 1, matrix listwise
eststo corr_low_lowermid

estpost correlate co2 reshare electricity_production energy_intensity government_effectiveness ///
    if uppermid_high == 1, matrix listwise
eststo corr_uppermid_high

esttab corr_low_lowermid corr_uppermid_high ///
    using "correlation_matrix_by_income_sets.rtf", ///
    not nostar unstack noobs compress ///
    mtitle("Low + Lower-middle" "Upper-middle + High") ///
    title("Correlation Matrix by Income-Group Set") ///
    replace

* Console summaries for quick inspection
summarize co2 reshare electricity_production energy_intensity government_effectiveness if low_lowermid == 1
summarize co2 reshare electricity_production energy_intensity government_effectiveness if uppermid_high == 1
