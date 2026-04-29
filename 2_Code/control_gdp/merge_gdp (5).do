/*==============================================================
  merge_gdp.do
  导入世界银行 GDP Excel 并与 WB_ESG_panel_final.dta 合并
  合并键: country_code + year
==============================================================*/

clear all
set more off

*--- 路径设置（请根据实际情况修改）---
global datadir "F:\Onedrive映射\1kcl\ESG\7QQMM907\DATA\Raw"

*===========================================
* 第一步：导入 Excel 并整理为面板格式
*===========================================

import excel using "${datadir}\API_NY.GDP.MKTP.CD_DS2_en_excel_v2_3.xls", ///
    sheet("Data") cellrange(A4) firstrow clear

* 删除多余变量
drop CountryName IndicatorName IndicatorCode

* 重命名国家代码
rename CountryCode country_code

* 将 Excel 列名（E F G ... BR）重命名为 yr1960 yr1961 ...
* E 对应 1960，共 66 列（1960-2025）
local yr = 1960
foreach var of varlist E-BR {
    rename `var' yr`yr'
    local yr = `yr' + 1
}

* 宽转长
reshape long yr, i(country_code) j(year)

* 重命名
rename yr gdp

* 转数值型（以防万一）
capture destring gdp, replace force

* 压缩并保存临时文件
compress
label variable gdp "GDP (current US$)"
label variable year "Year"
sort country_code year
save "${datadir}\gdp_long_temp.dta", replace

*===========================================
* 第二步：合并数据
*===========================================

use "${datadir}\WB_ESG_panel_final.dta", clear
sort country_code year

merge 1:1 country_code year using "${datadir}\gdp_long_temp.dta"

tab _merge

/*  _merge 说明：
    1 = 仅在 ESG 面板中（master only）
    2 = 仅在 GDP 数据中（using only）
    3 = 两者均有（matched）
*/

* 可根据需要保留匹配的观测值
* keep if _merge == 3
* drop _merge

save "${datadir}\WB_ESG_panel_merged.dta", replace

erase "${datadir}\gdp_long_temp.dta"

di as txt "合并完成！最终文件已保存为 WB_ESG_panel_merged.dta"
