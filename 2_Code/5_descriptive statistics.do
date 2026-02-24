

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

*---------------------------------------------------------------------------
* Step 2: state panel structure
*---------------------------------------------------------------------------
xtset id year

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

*---------------------------------------------------------------------------
* calculate mean change yearly
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




















