/*===========================================================================
Script:   8_case_study_bridge.do
Purpose:  Visualise the link between threshold regression results
          and qualitative case study selection (NLD & NOR)
===========================================================================*/

clear all
set more off

* Load & replicate regression sample
use "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\2_Processed\WB_ESG_panel_final.dta", clear
capture rename government_effectivenes government_effectiveness
xtset id year

drop if energy_intensity==. | electricity_production==. | reshare==. ///
      | co2==. | government_effectiveness==. | income==.
drop if year==2000
xtbalance, range(2002 2020)
xtset id year

gen ln_co2 = ln(co2)
gen ln_reshare = ln(reshare + 0.001)

* Regime assignment
gen regime = 0 if reshare < 0.9
replace regime = 1 if reshare >= 0.9 & reshare < 85.8
replace regime = 2 if reshare >= 85.8


*===========================================================================
* FIGURE 1: Threshold scatter with NLD & NOR highlighted
*           — The "bridge" figure between quant and qual
*===========================================================================

* Regime-specific fitted lines
reg ln_co2 reshare if regime == 0
predict yhat0 if regime == 0
reg ln_co2 reshare if regime == 1
predict yhat1 if regime == 1
reg ln_co2 reshare if regime == 2
predict yhat2 if regime == 2

* Identify NLD and NOR observations
gen is_nld = (country_code == "NLD")
gen is_nor = (country_code == "NOR")

twoway ///
    /* Background scatter: all other countries, faint */ ///
    (scatter ln_co2 reshare if regime == 0 & !is_nld & !is_nor, ///
        mcolor(gs12) msymbol(circle) msize(vtiny)) ///
    (scatter ln_co2 reshare if regime == 1 & !is_nld & !is_nor, ///
        mcolor(gs12) msymbol(circle) msize(vtiny)) ///
    (scatter ln_co2 reshare if regime == 2 & !is_nld & !is_nor, ///
        mcolor(gs12) msymbol(circle) msize(vtiny)) ///
    ///
    /* Regime fitted lines */ ///
    (line yhat0 reshare if regime == 0, ///
        sort lcolor(gs8) lwidth(medthick) lpattern(solid)) ///
    (line yhat1 reshare if regime == 1, ///
        sort lcolor(gs8) lwidth(medthick) lpattern(dash)) ///
    (line yhat2 reshare if regime == 2, ///
        sort lcolor(gs8) lwidth(medthick) lpattern(shortdash)) ///
    ///
    /* NLD: highlighted in blue */ ///
    (scatter ln_co2 reshare if is_nld, ///
        mcolor(navy) msymbol(circle) msize(small)) ///
    (connected ln_co2 reshare if is_nld, ///
        sort lcolor(navy) lwidth(medthin) lpattern(solid) ///
        mcolor(navy) msymbol(circle) msize(vsmall)) ///
    ///
    /* NOR: highlighted in green */ ///
    (scatter ln_co2 reshare if is_nor, ///
        mcolor(dkgreen) msymbol(diamond) msize(small)) ///
    (connected ln_co2 reshare if is_nor, ///
        sort lcolor(dkgreen) lwidth(medthin) lpattern(solid) ///
        mcolor(dkgreen) msymbol(diamond) msize(vsmall)) ///
    , ///
    /* Threshold lines */ ///
    xline(0.9, lcolor(cranberry) lwidth(thin) lpattern(dash)) ///
    xline(85.8, lcolor(cranberry) lwidth(thin) lpattern(dash)) ///
    ///
    /* Threshold labels */ ///
    text(4.3 3 "{&gamma}{subscript:1}=0.9%", ///
         size(vsmall) color(cranberry) placement(east)) ///
    text(4.3 83.5 "{&gamma}{subscript:2}=85.8%", ///
         size(vsmall) color(cranberry) placement(west)) ///
    ///
    /* Country labels with arrows */ ///
    text(2.35 13 "Netherlands", ///
         size(small) color(navy) placement(east)) ///
    text(1.9 63 "Norway", ///
         size(small) color(dkgreen) placement(east)) ///
    ///
    /* Axes */ ///
    ytitle("ln(CO{subscript:2} per capita)", size(medsmall)) ///
    xtitle("Renewable Energy Share (% of total)", size(medsmall)) ///
    xlabel(0(20)100, labsize(small)) ///
    ylabel(-4(2)4, labsize(small) grid glcolor(gs14) ///
           glwidth(vthin) glpattern(dot)) ///
    ///
    /* Legend */ ///
    legend(order(7 "Netherlands (2002–2020)" ///
                 9 "Norway (2002–2020)" ///
                 4 "Regime fitted lines") ///
           position(1) ring(0) cols(1) size(vsmall) ///
           region(lwidth(thin) lcolor(gs12) fcolor(white))) ///
    ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    xsize(6.5) ysize(4.5)

graph export "Fig_case_study_bridge.pdf", replace as(pdf)
graph export "Fig_case_study_bridge.tif", replace width(3900)

drop yhat0 yhat1 yhat2


*===========================================================================
* FIGURE 2: Dual time-series panel — NLD (left) & NOR (right)
*           Showing RE share + CO2 over 2002–2020
*===========================================================================

* --- Panel (a): Netherlands ---
twoway ///
    (connected reshare year if is_nld, ///
        lcolor(navy) lwidth(medthick) lpattern(solid) ///
        mcolor(navy) msymbol(circle) msize(small)) ///
    (connected co2 year if is_nld, ///
        lcolor(black) lwidth(medthick) lpattern(dash) ///
        mcolor(black) msymbol(square) msize(small) yaxis(2)) ///
    , ///
    ytitle("RE Share (%)", axis(1) size(medsmall) color(navy)) ///
    ytitle("CO{subscript:2} per capita (t)", axis(2) size(medsmall)) ///
    ylabel(0(2)12, axis(1) labsize(small) grid glcolor(gs14) ///
           glwidth(vthin) glpattern(dot)) ///
    ylabel(7(1)11, axis(2) labsize(small)) ///
    xtitle("") ///
    xlabel(2002(3)2020, labsize(small)) ///
    title("(a) Netherlands", size(medsmall) color(black) position(11)) ///
    text(2.2 2015 "RE: 1.9%{&rarr}10.7%", size(vsmall) color(navy)) ///
    text(10.3 2007 "CO{subscript:2}: 10.4{&rarr}7.5 t", ///
         size(vsmall) color(black)) ///
    legend(order(1 "RE Share" 2 "CO{subscript:2} per capita") ///
           position(6) rows(1) size(vsmall) ///
           region(lwidth(none) color(none))) ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    xsize(6) ysize(4) ///
    name(panel_nld, replace) nodraw


* --- Panel (b): Norway ---
twoway ///
    (connected reshare year if is_nor, ///
        lcolor(dkgreen) lwidth(medthick) lpattern(solid) ///
        mcolor(dkgreen) msymbol(diamond) msize(small)) ///
    (connected co2 year if is_nor, ///
        lcolor(black) lwidth(medthick) lpattern(dash) ///
        mcolor(black) msymbol(square) msize(small) yaxis(2)) ///
    , ///
    ytitle("RE Share (%)", axis(1) size(medsmall) color(dkgreen)) ///
    ytitle("CO{subscript:2} per capita (t)", axis(2) size(medsmall)) ///
    ylabel(54(2)62, axis(1) labsize(small) grid glcolor(gs14) ///
           glwidth(vthin) glpattern(dot)) ///
    ylabel(6.5(0.5)8.5, axis(2) labsize(small)) ///
    xtitle("") ///
    xlabel(2002(3)2020, labsize(small)) ///
    title("(b) Norway", size(medsmall) color(black) position(11)) ///
    text(60.5 2015 "RE: 59.5%{&rarr}60.9%", size(vsmall) color(dkgreen)) ///
    text(8.1 2007 "CO{subscript:2}: 7.6{&rarr}6.7 t", ///
         size(vsmall) color(black)) ///
    legend(order(1 "RE Share" 2 "CO{subscript:2} per capita") ///
           position(6) rows(1) size(vsmall) ///
           region(lwidth(none) color(none))) ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) lcolor(black) lwidth(thin)) ///
    xsize(6) ysize(4) ///
    name(panel_nor, replace) nodraw


* --- Combine ---
graph combine panel_nld panel_nor, ///
    cols(2) iscale(0.85) imargin(small) ///
    graphregion(color(white)) ///
    xsize(13) ysize(5)

graph export "Fig_NLD_NOR_timeseries.pdf", replace as(pdf)
graph export "Fig_NLD_NOR_timeseries.tif", replace width(3900)
