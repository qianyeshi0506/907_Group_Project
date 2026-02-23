/*===========================================================================
Project:  907 Group Project
Script:   4_merge.do
Purpose:  Merge income group classification into cleaned ESG panel
Input:    WB_ESG_panel_cleaned.dta, WB_income_group.dta
Output:   WB_ESG_panel_final.dta
===========================================================================*/

clear all
set more off

*---------------------------------------------------------------------------
* Step 1: 载入主数据集（ESG 面板）
*---------------------------------------------------------------------------
use "F:\\Onedrive映射\\1kcl\\ESG\\7QQMM907\\907_Group_Project\\1_Data\\2_Processed\\WB_ESG_panel_cleaned.dta", clear

*---------------------------------------------------------------------------
* Step 2: 合并收入分组数据
* many-to-one：ESG 面板中每个国家有多个年份，income group 每个国家只有一行
*---------------------------------------------------------------------------
merge m:1 country_code using"F:\\Onedrive映射\\1kcl\\ESG\\7QQMM907\\907_Group_Project\\1_Data\\2_Processed\\WB_income_group.dta"

*---------------------------------------------------------------------------
* Step 3: 检查合并结果
*---------------------------------------------------------------------------
* _merge == 1：仅在 ESG 面板中存在（无对应 income group）
* _merge == 2：仅在 income group 中存在（不在 ESG 面板中）
* _merge == 3：成功匹配

tab _merge

* 查看未匹配的国家（_merge == 1，可能是地区聚合体如 World, Euro Area 等）
list country_name country_code if _merge == 1, clean noobs

* 查看 income group 中多余的国家（_merge == 2）
list country_code if _merge == 2, clean noobs

*---------------------------------------------------------------------------
* Step 4: 处理未匹配观测
* 通常 _merge==2 是 income group 文件中有但 ESG 面板没有的国家，可直接删除
*---------------------------------------------------------------------------
drop if _merge == 2

* 删除合并标识变量
drop _merge

*---------------------------------------------------------------------------
* Step 5: 验证合并结果
*---------------------------------------------------------------------------
* 查看 income 变量的分布
tab income

* 确认 income 的编码含义（High/Low/Lower-middle/Upper-middle）
label list income

* 检查是否有国家缺失 income 分组
count if missing(income)
list country_name country_code if missing(income), clean noobs

*---------------------------------------------------------------------------
* Step 6: 声明面板结构并保存
*---------------------------------------------------------------------------
xtset id year

order country_name country_code id year income
sort id year

save "F:\\Onedrive映射\\1kcl\\ESG\\7QQMM907\\907_Group_Project\\1_Data\\2_Processed\\WB_ESG_panel_final.dta", replace

di "合并完成！共 " _N " 条观测值"
describe
