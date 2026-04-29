*=========================================
* World Bank ESG data：wide to long transformation
* raw file: World-Bank_ESG-data_25-26.xlsx
*=========================================

* import data from Excel file
import excel "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\1_Raw\World Bank_ESG data_25-26.xlsx", sheet("Data") clear

* rename forst 4 row variables
rename (A B C D) (country_name country_code series_name series_code)

* rename column 5 to 68 (corresponding 1960 to 2023)
local i = 0
foreach v of varlist E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP {
    local year = 1960 + `i'
    rename `v' yr`year'
    local i = `i' + 1
}

*delete original heading
drop if country_name == "Country Name"

* destring all year variables
destring yr1960-yr2023, replace force


* delete empty row
drop if missing(country_name) | country_name == "" 
drop if country_name == "Country Name"
drop if missing(country_code) | country_code == ""

*first reshape wide → long
reshape long yr, i(country_name country_code series_name series_code) j(year)
rename yr value

* remove illegal characters in series_code 
replace series_code = subinstr(series_code, ".", "_", .)
replace series_code = subinstr(series_code, "-", "_", .)
replace series_code = subinstr(series_code, " ", "_", .)

*delete variable name
drop series_name

* second reshape long → wide (panel)
* structure：country × year，every "column" equal a ESG index
reshape wide value, i(country_name country_code year) j(series_code) string

* organise variable prefix: variable as value+SeriesCode after reshape wide rename ，remove "value" prefix
rename value* *

* sorting
sort country_code year
order country_name country_code year

*save document to stata working directory
save "WB_ESG_panel.dta", replace
di "Finished！In total " _N " observations (country×year)"
describe
