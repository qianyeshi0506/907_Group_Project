//导入需要合并的文件
import excel "F:\Onedrive映射\1kcl\ESG\7QQMM907\907_Group_Project\1_Data\1_Raw\Word Bank_Income group.xlsx", sheet("List of economies") firstrow clear

//删掉没用的列
drop Economy Region Lendingcategory

//重命名
rename Code country_code

//将income group转化为数值类型，储存到新变量income中
encode Incomegroup ,gen(income)

//删除空值
drop if income == .

//保存处理后的文件
save "WB_income_group.dta"

