clear
use "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\2_Processed\WB_ESG_panel_final.dta"
cd "F:\Onedrive映射\1kcl\ESG\7QQMM907\DATA\Results"
* fix variable naming
capture rename government_effectivenes government_effectiveness

xtset id year //before deleting NA, balanced panel as data

drop if energy_intensity==. | electricity_production==. | reshare==. | co2==. | government_effectivenes==. | income==. //deleting NA

xtset id year //panel unbalanced after deletion

tab year

drop if year==2000 //tab year spotted 2001 data missing, delete 2000 data, change scope to 2002-2020

xtbalance, range(2002 2020) //rebalancing

xtset id year //varify result

summarize co2 reshare energy_intensity electricity_production government_effectivenes //take Ln for right skewed variable

gen ln_co2 = ln(co2)
gen ln_energy_intensity = ln(energy_intensity)
gen ln_reshare = ln(reshare + 0.001)
gen ln_electricity_production = ln(electricity_production + 0.001)

misstable summarize co2 reshare energy_intensity electricity_production government_effectiveness



* threshold regression

*=======================================
*single threshold model H0 vs H1
*=======================================
xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness, ///
    rx(ln_reshare) qx(reshare) thnum(1) trim(0.01) grid(400) bs(300)
tab year, gen(yr_)
xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness yr_2 - yr_19, ///
    rx(ln_reshare) qx(reshare) thnum(2) trim(0.01 0.01) grid(400) bs(300 300)
*=================================
* double threshold model H1 vs H2
*=====================================
xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness, ///
    rx(ln_reshare) qx(reshare) thnum(2) ///
    trim(0.01 0.01) grid(400) bs(300 300)

xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness, ///
    rx(ln_reshare) qx(reshare) thnum(3) ///
    trim(0.01 0.01 0.01) grid(400) bs(300 300 300)


xthreg ln_co2 ln_energy_intensity ln_electricity_production ///
    government_effectiveness yr_2 - yr_19, ///
    rx(ln_reshare) qx(reshare) thnum(3) ///
    trim(0.01 0.01 0.01) grid(400) bs(300 300 300)
	
testparm yr_2 - yr_19
*=========================================
* three threshold LR statistic graph
*=========================================

* first threshold：e(LR21)，354×2
_matplot e(LR21), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(a) First Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_triple_1, replace) nodraw

* second threshold：e(LR22)，354×2
_matplot e(LR22), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(b) Second Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_triple_2, replace) nodraw

* combine graph
graph combine LR_triple_1 LR_triple_2, ///
    cols(1) rows(3) ///
    title("Double Threshold LR Statistics", ///
          size(medsmall) color(black)) ///
    note("Note: Dashed line indicates 95% critical value (7.35).", ///
         size(vsmall) color(gs8)) ///
    graphregion(color(white)) ///
    xsize(12) ysize(20)

graph export "LR_double_threshold.png", replace width(2400)
