

/*===========================================================================
Project:  907 Group Project — ESG & Energy Transition Analysis
Script:   05_descriptive_stats.do
Purpose:  Generate descriptive statistics for all key variables
Input:    WB_ESG_panel_final.dta
===========================================================================*/

clear all
set more off

*---------------------------------------------------------------------------
* Step 1: load data set: ESG_final
*---------------------------------------------------------------------------
use "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\2_Processed\WB_ESG_panel_final.dta", clear
rename government_effectivenes government_effectiveness

xtset id year //before deleting NA, balanced panel as data

drop if energy_intensity==. | electricity_production==. | reshare==. | co2==. | government_effectivenes==. | income==. //deleting NA

xtset id year //panel unbalanced after deletion

tab year

drop if year==2000 //tab year spotted 2001 data missing, delete 2000 data, change scope to 2002-2020

xtbalance, range(2002 2020) //rebalancing

xtset id year //varify result

summarize co2 reshare energy_intensity electricity_production government_effectivenes //take Ln for right skewed variable
*---------------------------------------------------------------------------
* Step 2: Generate transformed variables
*---------------------------------------------------------------------------
gen ln_co2                    = ln(co2)
gen ln_energy_intensity       = ln(energy_intensity)
gen ln_reshare                = ln(reshare + 0.001)
gen ln_electricity_production = ln(electricity_production + 0.001)


*---------------------------------------------------------------------------
* Step 3: descriptive statistics for all samples 
*---------------------------------------------------------------------------
* basic statistics 
summarize co2 reshare electricity_production energy_intensity government_effectiveness income

* detailed statistics (include decimal points)
summarize co2 reshare electricity_production energy_intensity government_effectiveness, detail

*---------------------------------------------------------------------------
* Step 4: descriptive statistics as income group
*---------------------------------------------------------------------------
* income: 1=High, 2=Low, 3=Lower-middle, 4=Upper-middle
bysort income: summarize co2 reshare electricity_production energy_intensity government_effectiveness

*---------------------------------------------------------------------------
* Step 5: export formated descriptive statistics table (exportable to Word/LaTeX)
*---------------------------------------------------------------------------
estpost summarize co2 reshare electricity_production energy_intensity government_effectiveness


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

esttab using "descriptive_stats_regression_sample.rtf", ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    label ///
    title("Table 1: Descriptive Statistics (Regression Sample)") ///
    collabels("Mean" "Std. Dev." "Min" "Max" "Obs") ///
    nonum replace ///
    note("N = 3,325. Balanced panel: 175 countries, 2002-2020.")
*---------------------------------------------------------------------------
* Step 6: variable correlation matric 
*---------------------------------------------------------------------------
pwcorr co2 reshare electricity_production energy_intensity government_effectiveness, star(0.05)

* export correlation matric to word
estpost correlate co2 reshare electricity_production energy_intensity government_effectiveness, matrix listwise

esttab using "correlation_matrix.rtf", not nostar unstack noobs compress replace title("Table 2: Correlation Matrix")

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
* Global graph settings
set scheme s1mono          // clean monochrome base scheme
graph set window fontface "Times New Roman"


*---------------------------------------------------------------------------
* Figure 1: Time trends — CO₂ Emissions vs Renewable Energy Share
*---------------------------------------------------------------------------
preserve
collapse (mean) co2 reshare, by(year)

twoway ///
    (connected co2 year, ///
        lcolor(black) lwidth(medthick) lpattern(solid) ///
        mcolor(black) msymbol(circle) msize(small)) ///
    (connected reshare year, ///
        lcolor(gs6) lwidth(medthick) lpattern(dash) ///
        mcolor(gs6) msymbol(triangle) msize(small) yaxis(2)), ///
    ///
    ytitle("Mean CO{subscript:2} Emissions (metric tons per capita)", ///
           axis(1) size(medsmall)) ///
    ytitle("Mean Renewable Energy Share (%)", ///
           axis(2) size(medsmall)) ///
    xtitle("Year", size(medsmall)) ///
    ///
    xlabel(2002(2)2020, labsize(small) angle(0)) ///
    ylabel(3.8(0.2)4.8, axis(1) labsize(small) format(%4.1f) ///
           grid glcolor(gs14) glwidth(vthin) glpattern(dot)) ///
    ylabel(32(1)36, axis(2) labsize(small) format(%3.0f)) ///
    ///
    legend(order(1 "CO{subscript:2} emissions" ///
                 2 "Renewable energy share") ///
           position(6) rows(1) size(small) ///
           region(lwidth(none) color(none))) ///
    ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    xsize(6.5) ysize(4)

graph export "Fig1_trend_co2_reshare.pdf", replace as(pdf)
graph export "Fig1_trend_co2_reshare.tif", replace width(3900) // 6.5in × 600dpi

restore

*---------------------------------------------------------------------------
* Figure 2: Box plots — CO₂ by Income Group (original scale + log scale)
*---------------------------------------------------------------------------

* Panel (a): Original scale
graph box co2, over(income, ///
        relabel(1 "High" 2 "Low" 3 "Lower-middle" 4 "Upper-middle") ///
        label(labsize(small) angle(0))) ///
    ///
    box(1, fcolor(gs4)  lcolor(black) lwidth(thin)) ///
    box(2, fcolor(gs7)  lcolor(black) lwidth(thin)) ///
    box(3, fcolor(gs10) lcolor(black) lwidth(thin)) ///
    box(4, fcolor(gs13) lcolor(black) lwidth(thin)) ///
    ///
    medtype(cline) medline(lcolor(white) lwidth(medthick)) ///
    marker(1, mcolor(black) msize(vsmall)) ///
    marker(2, mcolor(black) msize(vsmall)) ///
    marker(3, mcolor(black) msize(vsmall)) ///
    marker(4, mcolor(black) msize(vsmall)) ///
    ///
    ytitle("CO{subscript:2} per Capita (metric tons)", size(medsmall)) ///
    b1title("Income Group", size(medsmall)) ///
    ///
    ylabel(0(10)50, labsize(small) grid glcolor(gs14) ///
           glwidth(vthin) glpattern(dot)) ///
    ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    xsize(6.5) ysize(4.5) ///
    name(box_co2, replace) nodraw

* Panel (b): Log scale
graph box ln_co2, over(income, ///
        relabel(1 "High" 2 "Low" 3 "Lower-middle" 4 "Upper-middle") ///
        label(labsize(small) angle(0))) ///
    ///
    box(1, fcolor(gs4)  lcolor(black) lwidth(thin)) ///
    box(2, fcolor(gs7)  lcolor(black) lwidth(thin)) ///
    box(3, fcolor(gs10) lcolor(black) lwidth(thin)) ///
    box(4, fcolor(gs13) lcolor(black) lwidth(thin)) ///
    ///
    medtype(cline) medline(lcolor(white) lwidth(medthick)) ///
    marker(1, mcolor(black) msize(vsmall)) ///
    marker(2, mcolor(black) msize(vsmall)) ///
    marker(3, mcolor(black) msize(vsmall)) ///
    marker(4, mcolor(black) msize(vsmall)) ///
    ///
    ytitle("ln(CO{subscript:2} per Capita)", size(medsmall)) ///
    b1title("Income Group", size(medsmall)) ///
    ///
    ylabel(, labsize(small) grid glcolor(gs14) ///
           glwidth(vthin) glpattern(dot)) ///
    ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    xsize(6.5) ysize(4.5) ///
    name(box_lnco2, replace) nodraw

* Combine panels
graph combine box_co2 box_lnco2, ///
    cols(2) iscale(0.85) ///
    graphregion(color(white)) ///
    xsize(13) ysize(5) ///
    note("(a){space 48}(b)", ///
         size(medsmall) position(6) ring(1))

graph export "Fig2_boxplot_co2_income.pdf", replace as(pdf)
graph export "Fig2_boxplot_co2_income.tif", replace width(3900)


*---------------------------------------------------------------------------
* Figure 3: Kernel density — ln(CO₂) by Income Group
*---------------------------------------------------------------------------
twoway ///
    (kdensity ln_co2 if income == 1, ///
        lcolor(black) lwidth(medthick) lpattern(solid)) ///
    (kdensity ln_co2 if income == 2, ///
        lcolor(black) lwidth(medthick) lpattern(dash)) ///
    (kdensity ln_co2 if income == 3, ///
        lcolor(gs6) lwidth(medthick) lpattern(shortdash)) ///
    (kdensity ln_co2 if income == 4, ///
        lcolor(gs6) lwidth(medthick) lpattern(longdash_dot)), ///
    ///
    ytitle("Density", size(medsmall)) ///
    xtitle("ln(CO{subscript:2} per Capita)", size(medsmall)) ///
    ///
    xlabel(-4(1)4, labsize(small)) ///
    ylabel(, labsize(small) grid glcolor(gs14) ///
           glwidth(vthin) glpattern(dot)) ///
    ///
    xline(0, lcolor(gs10) lwidth(thin) lpattern(dot)) ///
    ///
    legend(order(1 "High income" 2 "Low income" ///
                 3 "Lower-middle income" 4 "Upper-middle income") ///
           position(2) ring(0) cols(1) ///
           size(small) ///
           region(lwidth(thin) lcolor(gs10) fcolor(white))) ///
    ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    xsize(6.5) ysize(4.5)

graph export "Fig3_kdensity_lnco2_income.pdf", replace as(pdf)
graph export "Fig3_kdensity_lnco2_income.tif", replace width(3900)




















