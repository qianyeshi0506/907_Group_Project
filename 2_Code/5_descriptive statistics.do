

/*===========================================================================
Project:  907 Group Project — ESG & Energy Transition Analysis
Script:   05_descriptive_stats.do
Purpose:  Generate descriptive statistics for all key variables
Input:    WB_ESG_panel_final.dta
===========================================================================*/

clear all
set more off

*---------------------------------------------------------------------------
* Step 1: 载入最终数据集
*---------------------------------------------------------------------------
use "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\2_Processed\WB_ESG_panel_final.dta", clear
rename government_effectivenes government_effectiveness

*---------------------------------------------------------------------------
* Step 2: 声明面板结构
*---------------------------------------------------------------------------
xtset id year

*---------------------------------------------------------------------------
* Step 3: 全样本描述性统计
*---------------------------------------------------------------------------
* 基础统计量（obs, mean, sd, min, max）
summarize co2 reshare electricity_production energy_intensity government_effectiveness income

* 更详细的统计（含百分位数）
summarize co2 reshare electricity_production energy_intensity government_effectiveness, detail

*---------------------------------------------------------------------------
* Step 4: 按收入组分组描述性统计
*---------------------------------------------------------------------------
* income: 1=High, 2=Low, 3=Lower-middle, 4=Upper-middle
bysort income: summarize co2 reshare electricity_production energy_intensity government_effectiveness

*---------------------------------------------------------------------------
* Step 5: 输出格式化描述性统计表（可导出至 Word/LaTeX）
*---------------------------------------------------------------------------

* 安装命令：ssc install estout, replace
*---------------------------------------------------------------------------
* 添加变量标签（label），使输出表格显示可读名称
*---------------------------------------------------------------------------
*更改标签
label variable co2                    "CO2 Emissions (metric tons per capita)"
label variable reshare                "Renewable Energy Share (% of total)"
label variable electricity_production "Electricity from Coal (% of total)"
label variable energy_intensity       "Energy Intensity (MJ/\$2017 PPP GDP)"
label variable government_effectiveness "Government Effectiveness (WGI Estimate)"
label variable income                 "Income Group"

estpost summarize co2 reshare electricity_production energy_intensity government_effectiveness

esttab using "descriptive_stats.rtf", cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") label title("Table 1: Descriptive Statistics") collabels("Mean" "Std. Dev." "Min" "Max" "Obs") nonum replace


*---------------------------------------------------------------------------
* Step 6: 变量相关系数矩阵
*---------------------------------------------------------------------------
pwcorr co2 reshare electricity_production energy_intensity government_effectiveness, star(0.05)

* 输出相关系数矩阵至 Word
estpost correlate co2 reshare electricity_production energy_intensity government_effectiveness, matrix listwise

esttab using "correlation_matrix.rtf", not nostar unstack noobs compress replace title("Table 2: Correlation Matrix")

*---------------------------------------------------------------------------
* Step 7: 面板数据基本特征
*---------------------------------------------------------------------------
* 查看面板平衡性
xtdescribe

* 时间维度统计
tabstat co2 reshare electricity_production energy_intensity government_effectiveness, by(year) stats(mean) format(%9.3f)

* 国家维度统计（按收入组）
tabstat co2 reshare electricity_production energy_intensity government_effectiveness, by(income) stats(mean sd) format(%9.3f)

*---------------------------------------------------------------------------
* Step 8: 可视化——变量分布与趋势
*---------------------------------------------------------------------------

*---------------------------------------------------------------------------
* 生成年份均值变量
*---------------------------------------------------------------------------
bysort year: egen mean_co2    = mean(co2)
bysort year: egen mean_reshare = mean(reshare)

* 保留每年唯一一行用于绘图
preserve
collapse (mean) mean_co2 mean_reshare, by(year)
drop if mean_co2==. | mean_reshare==.

* 绘图

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

* 各收入组箱线图
*箱线图-CO2绝对值
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

*箱线图-CO₂ 取对数
gen ln_co2 = ln(co2 + 0.01)   // +0.01 避免 ln(0) 报错

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

* 核密度-ln_co2
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




















