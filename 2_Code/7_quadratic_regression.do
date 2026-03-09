
clear

use "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\2_Processed\WB_ESG_panel_final.dta", clear

cd "F:\Onedrive映射\1kcl\ESG\7QQMM907\DATA\Results"

capture rename government_effectivenes government_effectiveness

drop if energy_intensity==. | electricity_production==. | reshare==. | co2==. | government_effectiveness==. | income==.
drop if year==2000
xtbalance, range(2002 2020)
xtset id year

gen ln_co2 = ln(co2)
gen ln_reshare = ln(reshare + 0.001)
gen ln_energy_intensity = ln(energy_intensity)
gen ln_electricity_production = ln(electricity_production + 0.001)

*=========================================
* binominal regression: varify nonlinear relation between REShare and CO2
*=========================================
xtreg ln_co2 c.ln_reshare##c.ln_reshare ///
    ln_energy_intensity ln_electricity_production ///
    government_effectiveness ///
    i.year, fe vce(cluster id)

estimates store quadratic_fe


margins, dydx(ln_reshare)                            ///
    at(ln_reshare = (-7(0.1)4)) noestimcheck post

marginsplot, saving(me_plot, replace) nodraw

matrix M = r(b)

parmest, saving(me_results, replace) idnum(1)
use me_results, clear

gen x_val = -7 + (_n-1) * 0.1


gen region = 1 if x_val < -4          
replace region = 2 if x_val >= -4     


twoway ///
    (rarea min95 max95 x_val if region==1,           ///
     color(cranberry%20) lwidth(none))               ///
    (rarea min95 max95 x_val if region==2,           ///
     color(navy%25) lwidth(none))                    ///
    (line estimate x_val if region==1,               ///
     lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
    (line estimate x_val if region==2,               ///
     lcolor(navy) lwidth(medthick))                  ///
    (function y=0, range(-7 4)                       ///
     lcolor(gs6) lpattern(dash) lwidth(thin))        ///
    ,                                                ///
    xline(-4, lcolor(cranberry) lpattern(shortdash)  ///
          lwidth(medthick))                          ///
    xlabel(-7(1)4, labsize(small))                   ///
    ylabel(-0.6(0.1)0.25, labsize(small))            ///
    ytitle("dy/dx of ln(REShare)", size(small))      ///
    xtitle("ln(REShare + 0.001)", size(small))       ///
    title("Marginal Effect of ln(REShare) on ln(CO{subscript:2})", ///
          size(medsmall))                            ///
    legend(order(                                    ///
        2 "95% CI — Main sample region"              ///
        1 "95% CI — Sparse region (REShare < 2%)"   ///
        4 "ME — Main sample (ln ≥ −4)"              ///
        3 "ME — Sparse region (ln < −4, caution)")  ///
        pos(1) ring(0) cols(1) size(vsmall))         ///
    text(0.22 -5.8                                   ///
        "Positive ME in sparse"                      ///
        "region: n = `=scalar(n_sparse)'"            ///
        "(`=scalar(pct_sparse)'% of sample)"        ///
        , size(vsmall) color(cranberry))             ///
    note("Red dashed line = marginal effect in sparse region (REShare < 2%)." ///
         "Despite positive ME, this reflects data sparsity, not a robust"    ///
         "mechanism. Solid blue line represents the main sample region.",     ///
         size(vsmall))

graph export "marginal_effect_revised.png", replace width(2400)

*=========================================
* save result
*=========================================
esttab quadratic_fe using "quadratic_nonlinear.rtf", ///
    b(3) se(3) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    title("Quadratic Fixed-Effects Regression: Nonlinearity Test") ///
    mtitle("FE Quadratic") ///
    label ///
    scalars("N Observations" "r2_w Within R-sq" "r2_o Overall R-sq") ///
    note("Clustered standard errors at country level." ///
         "Country and year fixed effects included." ///
         "Dependent variable: ln(CO2). Threshold variable: ln(REShare + 0.001).") ///
    replace

*=========================================
* marginal effect: dln_co2/dln_reshare under different ln_reshare level
*=========================================
* ln(reshare+0.001) actual range between -7 to 4.6（corrsponding to reshare ≈ 0 to 100）
margins, dydx(ln_reshare) at(ln_reshare = (-7(1)4))

marginsplot, ///
    recast(line) recastci(rarea) ///
    title("Marginal Effect of ln(REShare) on ln(CO₂)", size(medsmall)) ///
    ytitle("dy/dx of ln(REShare)", size(small)) ///
    xtitle("ln(REShare + 0.001)", size(small)) ///
    yline(0, lpattern(dash) lcolor(gs8)) ///
    graphregion(color(white)) bgcolor(white) ///
    plotregion(lcolor(black) lwidth(thin))

graph export "marginal_effect_reshare.png", replace width(2400)
