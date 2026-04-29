//import data set to be merged
import excel "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\1_Raw\Word Bank_Income group.xlsx", sheet("List of economies") firstrow clear

//delete unused column
drop Economy Region Lendingcategory

//rename variable
rename Code country_code

//change "income group" variable type to value, store in new variable "income"
encode Incomegroup ,gen(income)

//delete empty value
drop if income == .

//save processed data
save "WB_income_group.dta"

