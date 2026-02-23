*=========================================
* World Bank ESG 数据：宽 → 长 → 宽格式转换
* 原始文件: World-Bank_ESG-data_25-26.xlsx
*=========================================

*导入 Excel 数据
import excel "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\1_Raw\World Bank_ESG data_25-26.xlsx", sheet("Data") clear

*重命名前四列变量
rename (A B C D) (country_name country_code series_name series_code)

* 第5列到第68列（对应 1960~2023）批量重命名
local i = 0
foreach v of varlist E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP {
    local year = 1960 + `i'
    rename `v' yr`year'
    local i = `i' + 1
}

*删除原表头
drop if country_name == "Country Name"

* destring 所有年份变量
destring yr1960-yr2023, replace force


* 删除空白行
drop if missing(country_name) | country_name == "" 
drop if country_name == "Country Name"
drop if missing(country_code) | country_code == ""

*第一次reshape wide → long
reshape long yr, i(country_name country_code series_name series_code) j(year)
rename yr value

* 先去除 series_code 中的非法字符
replace series_code = subinstr(series_code, ".", "_", .)
replace series_code = subinstr(series_code, "-", "_", .)
replace series_code = subinstr(series_code, " ", "_", .)

*删掉变量名称
drop series_name

* 第二次 reshape long → wide（面板）
* 结构：country × year，每列=一个ESG指标
reshape wide value, i(country_name country_code year) j(series_code) string

* 整理变量名前缀: reshape wide 后变量名为 value+SeriesCode，去掉 "value" 前缀
rename value* *

* 排序
sort country_code year
order country_name country_code year

*保存文件到stata工作目录
save "WB_ESG_panel.dta", replace
di "完成！共 " _N " 条观测（国家×年份）"
describe