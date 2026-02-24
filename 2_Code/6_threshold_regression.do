clear
use "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\2_Processed\WB_ESG_panel_final.dta"
cd "F:\Onedrive映射\1kcl\ESG\7QQMM907\DATA\Results"
* 修复变量名拼写
capture rename government_effectivenes government_effectiveness

xtset id year //未删除缺失值，数据为平衡面板

drop if energy_intensity==. | electricity_production==. | reshare==. | co2==. | government_effectivenes==. | income==. //删除缺失值

xtset id year //删除之后数据变成非平衡面板

tab year

drop if year==2000 //tab year 之后发现2001年数据完全缺失，因此删掉2000年数据，只保留2002-2020年数据

xtbalance, range(2002 2020) //非平衡面板---> 平衡面板

xtset id year //验证结果

summarize co2 reshare energy_intensity electricity_production government_effectivenes //右偏的变量需要取对数

gen ln_co2 = ln(co2)
gen ln_energy_intensity = ln(energy_intensity)
gen ln_reshare = ln(reshare + 0.001)
gen ln_electricity_production = ln(electricity_production + 0.001)

misstable summarize co2 reshare energy_intensity electricity_production government_effectiveness



* 运行门限回归

*=======================================
*单门槛
*=======================================

xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness, rx(ln_reshare) qx(ln_reshare) thnum(1) trim(0.01) grid(400) bs(300) 

estimates store threshold_single

*=================================
* 双门槛模型
*=====================================
xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness, rx(ln_reshare) qx(ln_reshare) thnum(2) trim(0.01 0.01) grid(400) bs(300 300)

estimates store threshold_double

*=========================================
* 三门槛模型
*===========================================
xthreg ln_co2 ln_energy_intensity ln_electricity_production government_effectiveness, rx(ln_reshare) qx(ln_reshare) thnum(3) trim(0.01 0.01 0.01) grid(400) bs(300 300 300)

estimates store threshold_triple

*=========================================
* 合并三个模型对比表（横向比较）
*=========================================
esttab threshold_single threshold_double threshold_triple ///
    using "threshold_comparison.rtf", ///
    b(3) se(3) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    title("Table 3: Panel Fixed-Effects Threshold Regression Results") ///
    mtitle("Single Threshold" "Double Threshold" "Triple Threshold") ///
    nobaselevels ///
    scalars("N Observations" "r2_w Within R-sq" "r2_o Overall R-sq") ///
    note("Standard errors in parentheses. * p<0.1, ** p<0.05, *** p<0.01." ///
         "All models include country and year fixed effects." ///
         "Threshold variable: ln(REShare + 0.001).") ///
    replace
ereturn list

*=========================================
* 三门槛 LR 统计量图
*=========================================

* 第一个门槛：e(LR21)，354×2
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

* 第二个门槛：e(LR22)，354×2
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

* 第三个门槛：e(LR3)，347×2
_matplot e(LR3), columns(1 2) ///
    yline(7.35, lpattern(dash) lcolor(black) lwidth(thin)) ///
    connect(direct) recast(line) ///
    lcolor(black) lwidth(medthick) msize(zero) ///
    ytitle("LR Statistics", size(small)) ///
    xtitle("Threshold Value of ln(REShare)", size(small)) ///
    title("(c) Third Threshold", size(medsmall) color(black)) ///
    graphregion(color(white)) plotregion(color(white) lcolor(black) lwidth(thin)) ///
    bgcolor(white) xsize(12) ysize(8) ///
    name(LR_triple_3, replace) nodraw

* 合并三图
graph combine LR_triple_1 LR_triple_2 LR_triple_3, ///
    cols(1) rows(3) ///
    title("Triple Threshold LR Statistics", ///
          size(medsmall) color(black)) ///
    note("Note: Dashed line indicates 95% critical value (7.35).", ///
         size(vsmall) color(gs8)) ///
    graphregion(color(white)) ///
    xsize(12) ysize(20)

graph export "LR_triple_threshold.png", replace width(2400)
