
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
* 二次项回归：验证 REShare 与 CO₂ 的非线性关系
*=========================================
xtreg ln_co2 c.ln_reshare##c.ln_reshare ///
    ln_energy_intensity ln_electricity_production ///
    government_effectiveness ///
    i.year, fe vce(cluster id)

estimates store quadratic_fe

*=========================================
* 保存结果
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
* 边际效应：在不同 ln_reshare 水平下 dln_co2/dln_reshare
*=========================================
* ln(reshare+0.001) 的实际范围约 -7 到 4.6（对应 reshare ≈ 0 到 100）
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
