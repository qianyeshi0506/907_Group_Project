*导入文件（需要替换成自己的路径）
use "F:\Onedrive映射\1kcl\ESG\7QQMM907\DATA\Cleaned\cleaned_data_WBI_ESG_all - 副本.dta"

*清洗数据
//删除不需要的变量
drop AG_LND_AGRI_ZS AG_LND_FRLS_HA AG_LND_FRST_ZS AG_PRD_FOOD_XD CC_EST IC_LGL_CRED_XQ IP_JRN_ARTC_SC IP_PAT_RESD IT_NET_USER_ZS NV_AGR_TOTL_ZS NY_ADJ_DFOR_GN_ZS NY_ADJ_DRES_GN_ZS NY_GDP_MKTP_KD_ZG PV_EST RL_EST VA_EST SP_UWT_TFRT SP_POP_65UP_TO_ZS SP_DYN_TFRT_IN SP_DYN_LE00_IN

drop EG_CFT_ACCS_ZS EG_ELC_ACCS_ZS EG_ELC_RNEW_ZS EG_IMP_CONS_ZS EG_USE_PCAP_KG_OE EN_ATM_METH_PC EN_ATM_NOXE_PC EN_ATM_PM25_MC_M3 EN_CLC_CDDY_XD EN_CLC_CSTP_ZS EN_CLC_GHGR_MT_CE EN_CLC_HDDY_XD EN_CLC_HEAT_XD EN_CLC_SPEI_XD EN_H2O_BDYS_ZS EN_LND_LTMP_DC EN_MAM_THRD_NO EN_POP_DNST ER_H2O_FWST_ZS ER_H2O_FWTL_ZS ER_PTD_TOTL_ZS GB_XPD_RSDV_GD_ZS

drop RQ_EST SD_ESR_PERF_XQ SE_ADT_LITR_ZS SE_ENR_PRSC_FM_ZS SE_PRM_ENRR SE_XPD_TOTL_GB_ZS SG_GEN_PARL_ZS SH_DTH_COMM_ZS SH_DYN_MORT SH_H2O_SMDW_ZS SH_MED_BEDS_ZS SH_STA_OWAD_ZS SH_STA_SMSS_ZS SI_DST_FRST_20 SI_POV_GINI SI_POV_NAHC SI_SPR_PCAP_ZG SL_TLF_0714_ZS SL_TLF_ACTI_ZS SL_TLF_CACT_FM_ZS SL_UEM_TOTL_ZS SM_POP_NETM SN_ITK_DEFC_ZS

drop if energy_intensity ==.
drop if electricity_production ==.| renewable_energy_consumption==.| fossil_fuel_energy_consumption==.| CO2_emissions==.| government_effectivenes==.
reg renewable_energy_consumption CO2_emissions government_effectivenes energy_intensity electricity_production

//重命名变量
rename EG_FEC_RNEW_ZS renewable_energy_consumption
rename EG_USE_COMM_FO_ZS fossil_fuel_energy_consumption
rename EG_ELC_COAL_ZS electricity_production
rename GE_EST government_effectivenes
rename EG_EGY_PRIM_PP_KD energy_intensity
rename EN_ATM_CO2E_PC CO2_emissions
encode country_code, gen(country_id)

*相关性分析

pwcorr renewable_energy_consumption fossil_fuel_energy_consumption
pwcorr renewable_energy_consumption CO2_emissions

*将reshare平方项纳入回归 验证非线性关系（用 factor variables 自动生成平方项）
 
xtset country_id year 

xtreg CO2_emissions renewable_energy_consumption c.renewable_energy_consumption c.renewable_energy_consumption#c.renewable_energy_consumption  energy_intensity 
government_effectivenes electricity_production i.year, fe vce(cluster country_id)

margins, dydx(renewable_energy_consumption) at(renewable_energy_consumption = (0(5)100))

*门限回归
///重命名变量
rename renewable_energy_consumption reshare
rename CO2_emissions co2
rename country_id id

xtdescribe

*处理非平衡面板
xtdescribe
bys id: egen temp1 = count(id)//记录id里面有几个观测值

* 运行xthreg
xtset id year
xthreg co2 reshare energy_intensity electricity_production government_effectivenes, rx(reshare) qx(reshare) thnum(1) trim(0.05) nboot(300) fixed(fe) nthresholds(1) trim(5)