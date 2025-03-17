set locale_ui zh_CN

// 设置工作目录（请将路径替换为您的实际数据路径）
cd "/Users/zhourongchang/project_cs/paper/毕业论文最终文件夹/county-district-reform-local-debt-empirical-analysis/projects/stata"

// 加载数据
use "毕业论文数据.dta", clear

summarize

// 设置面板数据
xtset city_id year

// 安装必要的 Stata 包（如果尚未安装，不覆盖已有版本）
// ssc install reghdfe
// ssc install outreg2
// ssc install psmatch2
// ssc install winsor2
// ssc install coefplot

// 数据准备：对地方债 (debt) 进行缩尾处理
winsor2 debt, cut(1 99) // Winsorize: remove 1% and 99% extreme values
drop debt // 删除原始的 debt 变量
rename debt_w debt // 将缩尾后的 debt_w 重命名为 debt

// ------------------------------------
// 1. Baseline Empirical Analysis
// ------------------------------------

// 1.1 Baseline Regression - DID only
reghdfe debt did, absorb(year city_id)
est store baseline_did
outreg2 baseline_did using "baseline_empirical_results.docx", word replace ctitle("Baseline: DID Only") keep(did)

// 1.2 Baseline Regression - Add Population Density (pd)
reghdfe debt did pd, absorb(year city_id)
est store baseline_pd
outreg2 baseline_pd using "baseline_empirical_results.docx", word append ctitle("Baseline: DID + PD") keep(did pd)

// 1.3 Baseline Regression - Add Local Economic Development (led)
reghdfe debt did pd led, absorb(year city_id)
est store baseline_led
outreg2 baseline_led using "baseline_empirical_results.docx", word append ctitle("Baseline: DID + PD + LED") keep(did pd led)

// 1.4 Baseline Regression - Add Foreign Direct Investment (fdi)
reghdfe debt did pd led fdi, absorb(year city_id)
est store baseline_fdi
outreg2 baseline_fdi using "baseline_empirical_results.docx", word append ctitle("Baseline: DID + PD + LED + FDI") keep(did pd led fdi)

// 1.5 Baseline Regression - Add Local Fiscal Deficit (lfd)
reghdfe debt did pd led fdi lfd, absorb(year city_id)
est store baseline_lfd
outreg2 baseline_lfd using "baseline_empirical_results.docx", word append ctitle("Baseline: DID + PD + LED + FDI + LFD") keep(did pd led fdi lfd)

// 1.6 Baseline Regression - Add Other Economic Indicators (oei)
reghdfe debt did pd led fdi lfd oei, absorb(year city_id)
est store baseline_oei
outreg2 baseline_oei using "baseline_empirical_results.docx", word append ctitle("Baseline: DID + PD + LED + FDI + LFD + OEI") keep(did pd led fdi lfd oei)

// 1.7 Baseline Regression - Full Model with All Controls (isu)
reghdfe debt did pd led fdi lfd oei isu, absorb(year city_id)
est store baseline_full
outreg2 baseline_full using "baseline_empirical_results.docx", word append ctitle("Baseline: Full Model") keep(did pd led fdi lfd oei isu)

// ------------------------------------
// 2. Robustness Checks
// ------------------------------------

// 2.1 Robustness Check - Parallel Trends Test
gen action = year - event_year

forvalues i = 13(-1)1 {
    gen pre_`i' = (action == -`i' & event_year != 0)
}

gen current = (action == 0 & event_year != 0)

// 生成处理后虚拟变量（las_1 到 las_13）
forvalues j = 1(1)13 {
    gen las_`j' = (action == `j' & did == 1)
    replace las_`j' = 0 if las_`j' == .
}

// 平行趋势检验回归（使用 xtreg，���定效应）
xtreg debt pre_13 pre_12 pre_11 pre_10 pre_9 pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 current las_1 las_2 las_3 las_4 las_5 las_6 las_7 las_8 las_9 las_10 las_11 las_12 las_13 pre_1 fdi lfd oei isu i.year, fe vce(cluster city_id)
est store parallel_trend

coefplot, baselevels omitted keep(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) vertical recast(connect) ///
    order(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) ///
    yline(0, lp(solid) lc(black)) xline(6, lp(solid)) ///
    ytitle("政策效应") xtitle("政策时点") ///
    xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" 5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" 10 "4" 11 "5") ///
    ciopts(recast(rcap) lc(black) lp(dash) lw(thin)) scale(1.0)

// 2.2 Robustness Check - PSM-DID
psmatch2 did pd led fdi lfd oei isu, outcome(debt) logit ate neighbor(4) caliper(0.05)
gen weight = _weight
reghdfe debt did if weight != ., absorb(year city_id)
est store psm_did
outreg2 psm_did using "robustness_results.docx", word replace ctitle("Robustness: PSM-DID") keep(did) addtext(Controls, Y)

// 2.3 Robustness Check - Placebo Test
set seed 1000
gen pseudo_did = runiform() > 0.5 // Generate a pseudo treatment variable
reghdfe debt pseudo_did pd led fdi lfd oei isu, absorb(year city_id)
est store placebo
outreg2 placebo using "robustness_results.docx", word append ctitle("Robustness: Placebo Test") keep(pseudo_did) addtext(Controls, Y)

// 2.4 Robustness Check - Excluding Sub-Provincial Cities
reghdfe debt did pd led fdi lfd oei isu if sub_provincial != 1, absorb(year city_id)
est store exclude_sub_provincial
outreg2 exclude_sub_provincial using "robustness_results.docx", word append ctitle("Robustness: Excluding Sub-Provincial Cities") keep(did) addtext(Controls, Y)

// 2.5 Robustness Check - Excluding Autonomous Regions
reghdfe debt did pd led fdi lfd oei isu if autonomous_region == 0, absorb(year city_id)
est store exclude_autonomous_region
outreg2 exclude_autonomous_region using "robustness_results.docx", word append ctitle("Robustness: Excluding Autonomous Regions") keep(did) addtext(Controls, Y)

// 2.6 Robustness Check - Excluding Interfering Policies
reghdfe debt did pd led fdi lfd oei isu if county_to_city == 0, absorb(year city_id)
est store exclude_county_to_city
outreg2 exclude_county_to_city using "robustness_results.docx", word append ctitle("Robustness: Excluding Interfering Policies") keep(did) addtext(Controls, Y)

// ------------------------------------
// 3. Heterogeneity Analysis
// ------------------------------------

// 3.1 区分只撤县设区一次和多次撤县设区的城市
gen did_once = 0  // 只撤县设区一次
replace did_once = 1 if did == 1 & mar == 0

gen did_multiple = 0  // 撤县设区多次
replace did_multiple = 1 if mar == 1

// 分组回归分析，基准组为未进行撤县设区的城市
// 3.1.1 只撤县设区一次的回归（排除撤县设区多次的城市）
reghdfe debt did_once pd led fdi lfd oei isu if did_multiple == 0, absorb(year city_id)
est store hetero_did_once
outreg2 hetero_did_once using "heterogeneity_results.docx", word replace ctitle("Heterogeneity: Once vs Never") keep(did_once) addtext(Controls, Y)

// 3.1.2 撤县设区多次的回归（排除只撤县设区一次的城市）
reghdfe debt did_multiple pd led fdi lfd oei isu if did_once == 0, absorb(year city_id)
est store hetero_did_multiple
outreg2 hetero_did_multiple using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Multiple vs Never") keep(did_multiple) addtext(Controls, Y)

// 3.2 财政压力对财政收入和心理账户的影响（交互项分析）
reghdfe debt did##c.fp pd led fdi lfd oei isu, absorb(year city_id)
est store hetero_fp
outreg2 hetero_fp using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Fiscal Pressure") keep(c.fp did#c.fp 1.did) addtext(Controls, Y)

// 3.3 Pre-New Budget Law Sample (Before 2014)
reghdfe debt did pd led fdi lfd oei isu if year < 2014, absorb(year city_id)
est store hetero_pre_2014
outreg2 hetero_pre_2014 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Pre-New Budget Law (Before 2014)") keep(did) addtext(Controls, Y)

// 3.4 Post-New Budget Law Sample (2014 and Later)
reghdfe debt did pd led fdi lfd oei isu if year >= 2014, absorb(year city_id)
est store hetero_post_2014
outreg2 hetero_post_2014 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Post-New Budget Law (2014 and Later)") keep(did) addtext(Controls, Y)

// 3.5 区域异质性分析：东部 vs 中西部
// 3.5.1 东部地区 (region_type == 1)
reghdfe debt did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store hetero_east
outreg2 hetero_east using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Eastern Region") keep(did) addtext(Controls, Y)

// 3.5.2 中西部地区 (region_type == 2)
reghdfe debt did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store hetero_midwest
outreg2 hetero_midwest using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Midwest Region") keep(did) addtext(Controls, Y)

// ------------------------------------
// 4. Land Finance Effects
// ------------------------------------

// 4.1 全样本分析
// 4.1.1 Land Transfer Revenue (ltr)
reghdfe ltr did pd led fdi lfd oei isu, absorb(year city_id)
est store land_ltr
outreg2 land_ltr using "land_finance_results.docx", word replace ctitle("Land Finance: Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.1.2 Land Transfer Area (lta)
reghdfe lta did pd led fdi lfd oei isu, absorb(year city_id)
est store land_lta
outreg2 land_lta using "land_finance_results.docx", word append ctitle("Land Finance: Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.1.3 Land Transfer Price (ltp)
reghdfe ltp did pd led fdi lfd oei isu, absorb(year city_id)
est store land_ltp
outreg2 land_ltp using "land_finance_results.docx", word append ctitle("Land Finance: Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.1.4 Commercial Land Transfer Revenue (cltr)
reghdfe cltr did pd led fdi lfd oei isu, absorb(year city_id)
est store land_cltr
outreg2 land_cltr using "land_finance_results.docx", word append ctitle("Land Finance: Commercial Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.1.5 Commercial Land Transfer Area (clta)
reghdfe clta did pd led fdi lfd oei isu, absorb(year city_id)
est store land_clta
outreg2 land_clta using "land_finance_results.docx", word append ctitle("Land Finance: Commercial Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.1.6 Commercial Land Transfer Price (cltp)
reghdfe cltp did pd led fdi lfd oei isu, absorb(year city_id)
est store land_cltp
outreg2 land_cltp using "land_finance_results.docx", word append ctitle("Land Finance: Commercial Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.1.7 Industrial Land Transfer Revenue (iltr)
reghdfe iltr did pd led fdi lfd oei isu, absorb(year city_id)
est store land_iltr
outreg2 land_iltr using "land_finance_results.docx", word append ctitle("Land Finance: Industrial Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.1.8 Industrial Land Transfer Area (ilta)
reghdfe ilta did pd led fdi lfd oei isu, absorb(year city_id)
est store land_ilta
outreg2 land_ilta using "land_finance_results.docx", word append ctitle("Land Finance: Industrial Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.1.9 Industrial Land Transfer Price (iltp)
reghdfe iltp did pd led fdi lfd oei isu, absorb(year city_id)
est store land_iltp
outreg2 land_iltp using "land_finance_results.docx", word append ctitle("Land Finance: Industrial Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.1.10 Service Land Transfer Revenue (sltr)
reghdfe sltr did pd led fdi lfd oei isu, absorb(year city_id)
est store land_sltr
outreg2 land_sltr using "land_finance_results.docx", word append ctitle("Land Finance: Service Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.1.11 Service Land Transfer Area (slta)
reghdfe slta did pd led fdi lfd oei isu, absorb(year city_id)
est store land_slta
outreg2 land_slta using "land_finance_results.docx", word append ctitle("Land Finance: Service Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.1.12 Service Land Transfer Price (sltp)
reghdfe sltp did pd led fdi lfd oei isu, absorb(year city_id)
est store land_sltp
outreg2 land_sltp using "land_finance_results.docx", word append ctitle("Land Finance: Service Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.1.13 Government Land Transfer Revenue (gltr)
reghdfe gltr did pd led fdi lfd oei isu, absorb(year city_id)
est store land_gltr
outreg2 land_gltr using "land_finance_results.docx", word append ctitle("Land Finance: Government Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.2 东部地区分析 (region_type == 1)
// 4.2.1 Land Transfer Revenue (ltr)
reghdfe ltr did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_ltr_east
outreg2 land_ltr_east using "land_finance_results_east.docx", word replace ctitle("Land Finance (East): Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.2.2 Land Transfer Area (lta)
reghdfe lta did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_lta_east
outreg2 land_lta_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.2.3 Land Transfer Price (ltp)
reghdfe ltp did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_ltp_east
outreg2 land_ltp_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.2.4 Commercial Land Transfer Revenue (cltr)
reghdfe cltr did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_cltr_east
outreg2 land_cltr_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Commercial Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.2.5 Commercial Land Transfer Area (clta)
reghdfe clta did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_clta_east
outreg2 land_clta_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Commercial Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.2.6 Commercial Land Transfer Price (cltp)
reghdfe cltp did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_cltp_east
outreg2 land_cltp_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Commercial Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.2.7 Industrial Land Transfer Revenue (iltr)
reghdfe iltr did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_iltr_east
outreg2 land_iltr_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Industrial Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.2.8 Industrial Land Transfer Area (ilta)
reghdfe ilta did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_ilta_east
outreg2 land_ilta_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Industrial Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.2.9 Industrial Land Transfer Price (iltp)
reghdfe iltp did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_iltp_east
outreg2 land_iltp_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Industrial Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.2.10 Service Land Transfer Revenue (sltr)
reghdfe sltr did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_sltr_east
outreg2 land_sltr_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Service Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.2.11 Service Land Transfer Area (slta)
reghdfe slta did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_slta_east
outreg2 land_slta_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Service Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.2.12 Service Land Transfer Price (sltp)
reghdfe sltp did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_sltp_east
outreg2 land_sltp_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Service Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.2.13 Government Land Transfer Revenue (gltr)
reghdfe gltr did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store land_gltr_east
outreg2 land_gltr_east using "land_finance_results_east.docx", word append ctitle("Land Finance (East): Government Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.3 中西部地区分析 (region_type == 2)
// 4.3.1 Land Transfer Revenue (ltr)
reghdfe ltr did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_ltr_midwest
outreg2 land_ltr_midwest using "land_finance_results_midwest.docx", word replace ctitle("Land Finance (Midwest): Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.3.2 Land Transfer Area (lta)
reghdfe lta did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_lta_midwest
outreg2 land_lta_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.3.3 Land Transfer Price (ltp)
reghdfe ltp did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_ltp_midwest
outreg2 land_ltp_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.3.4 Commercial Land Transfer Revenue (cltr)
reghdfe cltr did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_cltr_midwest
outreg2 land_cltr_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Commercial Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.3.5 Commercial Land Transfer Area (clta)
reghdfe clta did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_clta_midwest
outreg2 land_clta_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Commercial Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.3.6 Commercial Land Transfer Price (cltp)
reghdfe cltp did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_cltp_midwest
outreg2 land_cltp_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Commercial Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.3.7 Industrial Land Transfer Revenue (iltr)
reghdfe iltr did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_iltr_midwest
outreg2 land_iltr_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Industrial Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.3.8 Industrial Land Transfer Area (ilta)
reghdfe ilta did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_ilta_midwest
outreg2 land_ilta_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Industrial Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.3.9 Industrial Land Transfer Price (iltp)
reghdfe iltp did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_iltp_midwest
outreg2 land_iltp_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Industrial Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.3.10 Service Land Transfer Revenue (sltr)
reghdfe sltr did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_sltr_midwest
outreg2 land_sltr_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Service Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 4.3.11 Service Land Transfer Area (slta)
reghdfe slta did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_slta_midwest
outreg2 land_slta_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Service Land Transfer Area") keep(did) addtext(Controls, Y)

// 4.3.12 Service Land Transfer Price (sltp)
reghdfe sltp did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_sltp_midwest
outreg2 land_sltp_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Service Land Transfer Price") keep(did) addtext(Controls, Y)

// 4.3.13 Government Land Transfer Revenue (gltr)
reghdfe gltr did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store land_gltr_midwest
outreg2 land_gltr_midwest using "land_finance_results_midwest.docx", word append ctitle("Land Finance (Midwest): Government Land Transfer Revenue") keep(did) addtext(Controls, Y)

// ------------------------------------
// 5. 政府信用与隐形担保
// ------------------------------------

// 5.1 全样本分析
// 5.1.0 Financing Cost (fc)
reghdfe fc did pd led fdi lfd oei isu, absorb(year city_id)
est store fiscal_fc
outreg2 fiscal_fc using "fiscal_revenue_results.docx", word replace ctitle("Fiscal Revenue: Financing Cost") keep(did) addtext(Controls, Y)

// 5.1.1 Tax Revenue (tr)
reghdfe tr did pd led fdi lfd oei isu, absorb(year city_id)
est store fiscal_tr
outreg2 fiscal_tr using "fiscal_revenue_results.docx", word append ctitle("Fiscal Revenue: Tax Revenue") keep(did) addtext(Controls, Y)

// 5.1.2 VAT Revenue (vatr)
reghdfe vatr did pd led fdi lfd oei isu, absorb(year city_id)
est store fiscal_vatr
outreg2 fiscal_vatr using "fiscal_revenue_results.docx", word append ctitle("Fiscal Revenue: VAT Revenue") keep(did) addtext(Controls, Y)

// 5.1.3 Economic Agglomeration (eal)
reghdfe eal did pd led fdi lfd oei isu, absorb(year city_id)
est store fiscal_eal
outreg2 fiscal_eal using "fiscal_revenue_results.docx", word append ctitle("Fiscal Revenue: Economic Agglomeration") keep(did) addtext(Controls, Y)

// 5.2 东部地区分析 (region_type == 1)
// 5.2.0 Financing Cost (fc)
reghdfe fc did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store fiscal_fc_east
outreg2 fiscal_fc_east using "fiscal_revenue_results_east.docx", word replace ctitle("Fiscal Revenue (East): Financing Cost") keep(did) addtext(Controls, Y)

// 5.2.1 Tax Revenue (tr)
reghdfe tr did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store fiscal_tr_east
outreg2 fiscal_tr_east using "fiscal_revenue_results_east.docx", word append ctitle("Fiscal Revenue (East): Tax Revenue") keep(did) addtext(Controls, Y)

// 5.2.2 VAT Revenue (vatr)
reghdfe vatr did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store fiscal_vatr_east
outreg2 fiscal_vatr_east using "fiscal_revenue_results_east.docx", word append ctitle("Fiscal Revenue (East): VAT Revenue") keep(did) addtext(Controls, Y)

// 5.2.3 Economic Agglomeration (eal)
reghdfe eal did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store fiscal_eal_east
outreg2 fiscal_eal_east using "fiscal_revenue_results_east.docx", word append ctitle("Fiscal Revenue (East): Economic Agglomeration") keep(did) addtext(Controls, Y)

// 5.3 中西部地区分析 (region_type == 2)
// 5.3.0 Financing Cost (fc)
reghdfe fc did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store fiscal_fc_midwest
outreg2 fiscal_fc_midwest using "fiscal_revenue_results_midwest.docx", word replace ctitle("Fiscal Revenue (Midwest): Financing Cost") keep(did) addtext(Controls, Y)

// 5.3.1 Tax Revenue (tr)
reghdfe tr did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store fiscal_tr_midwest
outreg2 fiscal_tr_midwest using "fiscal_revenue_results_midwest.docx", word append ctitle("Fiscal Revenue (Midwest): Tax Revenue") keep(did) addtext(Controls, Y)

// 5.3.2 VAT Revenue (vatr)
reghdfe vatr did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store fiscal_vatr_midwest
outreg2 fiscal_vatr_midwest using "fiscal_revenue_results_midwest.docx", word append ctitle("Fiscal Revenue (Midwest): VAT Revenue") keep(did) addtext(Controls, Y)

// 5.3.3 Economic Agglomeration (eal)
reghdfe eal did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store fiscal_eal_midwest
outreg2 fiscal_eal_midwest using "fiscal_revenue_results_midwest.docx", word append ctitle("Fiscal Revenue (Midwest): Economic Agglomeration") keep(did) addtext(Controls, Y)

// ------------------------------------
// 6. Urban Expenditure and Low-Quality Development
// ------------------------------------


// 6.1 全样本分析
// 6.1.1 Industrial Land Transfer (ilta)
reghdfe ilta did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_ilta
outreg2 urban_ilta using "urban_expenditure_results.docx", word replace ctitle("Urban Expenditure: Industrial Land Transfer") keep(did) addtext(Controls, Y)

// 6.1.2 Land Resource Misallocation Index (lri)
reghdfe lri did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_lri
outreg2 urban_lri using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Land Resource Misallocation Index") keep(did) addtext(Controls, Y)

reghdfe lri_2 did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_lri_2
outreg2 urban_lri_2 using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Land Resource Misallocation Index 2") keep(did) addtext(Controls, Y)

reghdfe lri_3 did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_lri_3
outreg2 urban_lri_3 using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Land Resource Misallocation Index 3") keep(did) addtext(Controls, Y)

// 6.1.3 Urban Sprawl (ue)
reghdfe ue did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_ue
outreg2 urban_ue using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Urban Sprawl") keep(did) addtext(Controls, Y)

reghdfe uei did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_uei
outreg2 urban_uei using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Urban Sprawl Index") keep(did) addtext(Controls, Y)

reghdfe light_sum did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_light_sum
outreg2 urban_light_sum using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Urban Sprawl (Light Sum)") keep(did) addtext(Controls, Y)

reghdfe light_average did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_light_average
outreg2 urban_light_average using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Urban Sprawl (Light Average)") keep(did) addtext(Controls, Y)

// 6.1.4 Infrastructure Investment (ici)
reghdfe ici did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_ici
outreg2 urban_ici using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Infrastructure Investment") keep(did) addtext(Controls, Y)

// 6.1.5 Maintenance Cost (imc)
reghdfe imc did pd led fdi lfd oei isu, absorb(year city_id)
est store urban_imc
outreg2 urban_imc using "urban_expenditure_results.docx", word append ctitle("Urban Expenditure: Maintenance Cost") keep(did) addtext(Controls, Y)

// 6.2 东部地区分析 (region_type == 1)
// 6.2.1 Industrial Land Transfer (ilta)
reghdfe ilta did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_ilta_east
outreg2 urban_ilta_east using "urban_expenditure_results_east.docx", word replace ctitle("Urban Expenditure (East): Industrial Land Transfer") keep(did) addtext(Controls, Y)

// 6.2.2 Land Resource Misallocation Index (lri)
reghdfe lri did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_lri_east
outreg2 urban_lri_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Land Resource Misallocation Index") keep(did) addtext(Controls, Y)

reghdfe lri_2 did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_lri_2_east
outreg2 urban_lri_2_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Land Resource Misallocation Index 2") keep(did) addtext(Controls, Y)

reghdfe lri_3 did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_lri_3_east
outreg2 urban_lri_3_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Land Resource Misallocation Index 3") keep(did) addtext(Controls, Y)

// 6.2.3 Urban Sprawl (ue)
reghdfe ue did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_ue_east
outreg2 urban_ue_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Urban Sprawl") keep(did) addtext(Controls, Y)

reghdfe uei did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_uei_east
outreg2 urban_uei_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Urban Sprawl Index") keep(did) addtext(Controls, Y)

reghdfe light_sum did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_light_sum_east
outreg2 urban_light_sum_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Urban Sprawl (Light Sum)") keep(did) addtext(Controls, Y)

reghdfe light_average did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_light_average_east
outreg2 urban_light_average_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Urban Sprawl (Light Average)") keep(did) addtext(Controls, Y)

// 6.2.4 Infrastructure Investment (ici)
reghdfe ici did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_ici_east
outreg2 urban_ici_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Infrastructure Investment") keep(did) addtext(Controls, Y)

// 6.2.5 Maintenance Cost (imc)
reghdfe imc did pd led fdi lfd oei isu if region_type == 1, absorb(year city_id)
est store urban_imc_east
outreg2 urban_imc_east using "urban_expenditure_results_east.docx", word append ctitle("Urban Expenditure (East): Maintenance Cost") keep(did) addtext(Controls, Y)

// 6.3 中西部地区分析 (region_type == 2)
// 6.3.1 Industrial Land Transfer (ilta)
reghdfe ilta did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_ilta_midwest
outreg2 urban_ilta_midwest using "urban_expenditure_results_midwest.docx", word replace ctitle("Urban Expenditure (Midwest): Industrial Land Transfer") keep(did) addtext(Controls, Y)

// 6.3.2 Land Resource Misallocation Index (lri)
reghdfe lri did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_lri_midwest
outreg2 urban_lri_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Land Resource Misallocation Index") keep(did) addtext(Controls, Y)

reghdfe lri_2 did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_lri_2_midwest
outreg2 urban_lri_2_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Land Resource Misallocation Index 2") keep(did) addtext(Controls, Y)

reghdfe lri_3 did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_lri_3_midwest
outreg2 urban_lri_3_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Land Resource Misallocation Index 3") keep(did) addtext(Controls, Y)

// 6.3.3 Urban Sprawl (ue)
reghdfe ue did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_ue_midwest
outreg2 urban_ue_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Urban Sprawl") keep(did) addtext(Controls, Y)

reghdfe uei did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_uei_midwest
outreg2 urban_uei_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Urban Sprawl Index") keep(did) addtext(Controls, Y)

reghdfe light_sum did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_light_sum_midwest
outreg2 urban_light_sum_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Urban Sprawl (Light Sum)") keep(did) addtext(Controls, Y)

reghdfe light_average did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_light_average_midwest
outreg2 urban_light_average_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Urban Sprawl (Light Average)") keep(did) addtext(Controls, Y)

// 6.3.4 Infrastructure Investment (ici)
reghdfe ici did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_ici_midwest
outreg2 urban_ici_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Infrastructure Investment") keep(did) addtext(Controls, Y)

// 6.3.5 Maintenance Cost (imc)
reghdfe imc did pd led fdi lfd oei isu if region_type == 2, absorb(year city_id)
est store urban_imc_midwest
outreg2 urban_imc_midwest using "urban_expenditure_results_midwest.docx", word append ctitle("Urban Expenditure (Midwest): Maintenance Cost") keep(did) addtext(Controls, Y)

// ------------------------------------
// 7. Final Results and Save Data
// ------------------------------------
outreg2 using "final_results.docx", word replace ctitle("Final Results Summary") addtext(Controls, N)

save "毕业论文数据_分析后.dta", replace
