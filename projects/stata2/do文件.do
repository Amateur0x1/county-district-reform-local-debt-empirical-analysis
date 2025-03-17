// 设置界面语言为中文（如果适用）
set locale_ui zh_CN

// 设置工作目录（请替换为您的实际路径）
cd "/Users/zhourongchang/project_cs/paper/毕业论文最终文件夹/county-district-reform-local-debt-empirical-analysis/projects/stata2"

// 加载数据
use "毕业论文数据.dta", clear

// ln 数据
gen cmc_l = ln(cmc)
foreach var in cmc {
    drop `var'
    rename `var'_l `var'
}

// 描述性统计
summarize

// 设置面板数据
xtset city_id year

// 安装必要的 Stata 包（如果尚未安装，不覆盖已有版本，运行时请取消注释）
// ssc install reghdfe
// ssc install outreg2
// ssc install psmatch2
// ssc install winsor2
// ssc install coefplot

// 数据准备：对地方债 (debt) 进行缩尾处理
winsor2 debt, cut(1 99) // Winsorize: 去除 1% 和 99% 的极端值
drop debt               // 删除原始 debt 变量
rename debt_w debt      // 将缩尾后的 debt_w 重命名为 debt
winsor2 lrae2, cut(5 95) // Winsorize: 去除 1% 和 99% 的极端值
drop lrae2               // 删除原始 debt 变量
rename lrae2_w lrae2     // 将缩尾后的 debt_w 重命名为 debt

// ------------------------------------
// 1. 基准回归 (Baseline Regression) - 逐步加入控制变量
// ------------------------------------

// 1.1 仅包含 did
reghdfe debt did, absorb(year city_id)
est store baseline_did
outreg2 baseline_did using "baseline_results.docx", word replace ctitle("Baseline: DID Only") keep(did)

// 1.2 添加人口密度 (pd)
reghdfe debt did pd, absorb(year city_id)
est store baseline_pd
outreg2 baseline_pd using "baseline_results.docx", word append ctitle("Baseline: DID + PD") keep(did pd)

// 1.3 添加其他经济指标 (oei)
reghdfe debt did pd oei, absorb(year city_id)
est store baseline_oei
outreg2 baseline_oei using "baseline_results.docx", word append ctitle("Baseline: DID + PD + OEI") keep(did pd oei)

// 1.4 添加二产比例 (is)
reghdfe debt did pd oei is, absorb(year city_id)
est store baseline_is
outreg2 baseline_is using "baseline_results.docx", word append ctitle("Baseline: DID + PD + OEI + IS") keep(did pd oei is)

// 1.5 添加财政分权程度 (fdi)
reghdfe debt did pd oei is fdi, absorb(year city_id)
est store baseline_fdi
outreg2 baseline_fdi using "baseline_results.docx", word append ctitle("Baseline: DID + PD + OEI + IS + FDI") keep(did pd oei is fdi)

// 1.6 添加经济发展水平 (egl cmc) - 完整模型
reghdfe debt did pd oei is fdi egl cmc, absorb(year city_id)
est store baseline_full
outreg2 baseline_full using "baseline_results.docx", word append ctitle("Baseline: Full Model") keep(did pd oei is fdi egl cmc)
// ------------------------------------
// 2. 稳健性检验 (Robustness Checks)
// ------------------------------------

// 2.1 平行趋势检验 (Parallel Trends Test)
gen action = year - event_year
forvalues i = 13(-1)1 {
    gen pre_`i' = (action == -`i' & event_year != 0)
}
gen current = (action == 0 & event_year != 0)
forvalues j = 1(1)13 {
    gen las_`j' = (action == `j' & did == 1)
    replace las_`j' = 0 if las_`j' == .
}
xtreg debt pre_13 pre_12 pre_11 pre_10 pre_9 pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 current las_1 las_2 las_3 las_4 las_5 las_6 las_7 las_8 las_9 las_10 las_11 las_12 las_13 pd oei is fdi egl cmc i.year, fe vce(cluster city_id)
est store parallel_trend
coefplot, baselevels omitted keep(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) vertical recast(connect) ///
    order(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) ///
    yline(0, lp(solid) lc(black)) xline(6, lp(solid)) ///
    ytitle("政策效应") xtitle("政策时点") ///
    xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" 5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" 10 "4" 11 "5") ///
    ciopts(recast(rcap) lc(black) lp(dash) lw(thin)) scale(1.0)

// 2.2 PSM-DID
psmatch2 did pd oei is fdi egl cmc, outcome(debt) logit ate neighbor(4) caliper(0.05)
gen weight = _weight
reghdfe debt did if weight != ., absorb(year city_id)
est store psm_did
outreg2 psm_did using "robustness_results.docx", word replace ctitle("Robustness: PSM-DID") keep(did) addtext(Controls, Y)

// 2.3 安慰剂检验 (Placebo Test)
set seed 1000
gen pseudo_did = runiform() > 0.5
reghdfe debt pseudo_did pd oei is fdi egl cmc, absorb(year city_id)
est store placebo
outreg2 placebo using "robustness_results.docx", word append ctitle("Robustness: Placebo Test") keep(pseudo_did) addtext(Controls, Y)

// 2.4 排除副省级城市
reghdfe debt did pd oei is fdi egl cmc if sub_provincial != 1, absorb(year city_id)
est store exclude_sub_provincial
outreg2 exclude_sub_provincial using "robustness_results.docx", word append ctitle("Robustness: Excluding Sub-Provincial Cities") keep(did) addtext(Controls, Y)

// 2.5 排除自治区
reghdfe debt did pd oei is fdi egl cmc if autonomous_region == 0, absorb(year city_id)
est store exclude_autonomous_region
outreg2 exclude_autonomous_region using "robustness_results.docx", word append ctitle("Robustness: Excluding Autonomous Regions") keep(did) addtext(Controls, Y)

// 2.6 排除干扰政策
reghdfe debt did pd oei is fdi egl cmc if county_to_city == 0, absorb(year city_id)
est store exclude_county_to_city
outreg2 exclude_county_to_city using "robustness_results.docx", word append ctitle("Robustness: Excluding Interfering Policies") keep(did) addtext(Controls, Y)

// ------------------------------------
// 3. 异质性分析 (Heterogeneity Analysis)
// ------------------------------------

// 3.1 城市规模 (cs) - 调节效应
reghdfe debt did##c.cs pd oei is fdi egl cmc, absorb(year city_id)
est store hetero_cs_mod
outreg2 hetero_cs_mod using "heterogeneity_results.docx", word replace ctitle("Heterogeneity: City Scale (Moderation)") keep(did c.cs did#c.cs) addtext(Controls, Y)

// 3.2 人口集聚程度 (pad) - 调节效应
reghdfe debt did##c.pad pd oei is fdi egl cmc, absorb(year city_id)
est store hetero_pad_mod
outreg2 hetero_pad_mod using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Population Agglomeration (Moderation)") keep(did c.pad did#c.pad) addtext(Controls, Y)

// 3.3 区域异质性 (region_type)
reghdfe debt did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
est store hetero_east
outreg2 hetero_east using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Eastern Region") keep(did) addtext(Controls, Y)
reghdfe debt did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
est store hetero_midwest
outreg2 hetero_midwest using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Midwest Region") keep(did) addtext(Controls, Y)

// 3.4 财政压力 (fp) - 调节效应
reghdfe debt did##c.fp pd oei is fdi egl cmc, absorb(year city_id)
est store hetero_pad_mod
outreg2 hetero_pad_mod using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Population Agglomeration (Moderation)") keep(did c.pad did#c.pad) addtext(Controls, Y)

// ------------------------------------
// 4. 机制分析1 (Mechanism Analysis 1)
// ------------------------------------

// 4.1 土地资源配置效率1 (lrae)
reghdfe lrae did pd oei is fdi egl cmc, absorb(year city_id)
est store mech1_lrae
outreg2 mech1_lrae using "mechanism1_results.docx", word replace ctitle("Mechanism 1: Land Resource Allocation Efficiency 1") keep(did) addtext(Controls, Y)

// 4.2 土地资源配置效率2 (lrae2)
reghdfe lrae2 did pd oei is fdi egl cmc, absorb(year city_id)
est store mech1_lrae2
outreg2 mech1_lrae2 using "mechanism1_results.docx", word append ctitle("Mechanism 1: Land Resource Allocation Efficiency 2") keep(did) addtext(Controls, Y)

// ------------------------------------
// 5. 机制分析1 + 异质性分析 (Mechanism 1 + Heterogeneity)
// ------------------------------------

// 5.1 产业升级水平 (isu) - 百分之五十分割 + 调节效应
egen isu_median = median(isu)
gen isu_high = (isu > isu_median)
gen isu_low = (isu <= isu_median)

reghdfe lrae did pd oei is fdi egl cmc if isu_high == 1, absorb(year city_id)
est store mech1_isu_high
outreg2 mech1_isu_high using "mechanism1_hetero_results.docx", word replace ctitle("Mech 1 Hetero: High Industry Upgrade (lrae)") keep(did) addtext(Controls, Y)

reghdfe lrae did pd oei is fdi egl cmc if isu_low == 1, absorb(year city_id)
est store mech1_isu_low
outreg2 mech1_isu_low using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: Low Industry Upgrade (lrae)") keep(did) addtext(Controls, Y)

reghdfe lrae did##c.isu pd oei is fdi egl cmc, absorb(year city_id)
est store mech1_isu_mod
outreg2 mech1_isu_mod using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: Industry Upgrade Moderation (lrae)") keep(did c.isu did#c.isu) addtext(Controls, Y)

// 5.2 人口流入 (pi) - 是否大于1
gen pi_high = (pi > 1)
gen pi_low = (pi <= 1)
reghdfe lrae did pd oei is fdi egl cmc if pi_high == 1, absorb(year city_id)
est store mech1_pi_high
outreg2 mech1_pi_high using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: High Population Inflow (lrae)") keep(did) addtext(Controls, Y)

reghdfe lrae did pd oei is fdi egl cmc if pi_low == 1, absorb(year city_id)
est store mech1_pi_low
outreg2 mech1_pi_low using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: Low Population Inflow (lrae)") keep(did) addtext(Controls, Y)

reghdfe lrae2 did##c.pi pd oei is fdi egl cmc, absorb(year city_id)
est store mech1_isu_mod
outreg2 mech1_isu_mod using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: Industry Upgrade Moderation (lrae)") keep(did c.isu did#c.isu) addtext(Controls, Y)


// 5.3 多中心结构 (mc) - 百分之五十分割 + 调节效应
egen mc_median = median(mc)
gen mc_high = (mc > mc_median)
gen mc_low = (mc <= mc_median)
reghdfe lrae did pd oei is fdi egl cmc if mc_high == 1, absorb(year city_id)
est store mech1_mc_high
outreg2 mech1_mc_high using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: High Multi-Center Structure (lrae)") keep(did) addtext(Controls, Y)
reghdfe lrae did pd oei is fdi egl cmc if mc_low == 1, absorb(year city_id)
est store mech1_mc_low
outreg2 mech1_mc_low using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: Low Multi-Center Structure (lrae)") keep(did) addtext(Controls, Y)
reghdfe lrae did##c.mc pd oei is fdi egl cmc, absorb(year city_id)
est store mech1_mc_mod
outreg2 mech1_mc_mod using "mechanism1_hetero_results.docx", word append ctitle("Mech 1 Hetero: Multi-Center Structure Moderation (lrae)") keep(did c.mc did#c.mc) addtext(Controls, Y)

// ------------------------------------
// 6. 机制分析2 (Mechanism Analysis 2)
// ------------------------------------

// 6.1 融资成本 (fc)
reghdfe fc did pd oei is fdi egl cmc, absorb(year city_id)
est store mech2_fc
outreg2 mech2_fc using "mechanism2_results.docx", word replace ctitle("Mechanism 2: Financing Cost") keep(did) addtext(Controls, Y)

// 6.2 区域异质性 (region_type)
reghdfe fc did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
est store mech2_fc_east
outreg2 mech2_fc_east using "mechanism2_results.docx", word append ctitle("Mechanism 2: Financing Cost (East)") keep(did) addtext(Controls, Y)
reghdfe fc did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
est store mech2_fc_midwest
outreg2 mech2_fc_midwest using "mechanism2_results.docx", word append ctitle("Mechanism 2: Financing Cost (Midwest)") keep(did) addtext(Controls, Y)

// 6.3 增值税 (vatr)
reghdfe vatr did pd oei is fdi egl cmc, absorb(year city_id)
est store mech2_vatr
outreg2 mech2_vatr using "mechanism2_results.docx", word append ctitle("Mechanism 2: VAT Revenue") keep(did) addtext(Controls, Y)

// 6.4 税收 (tr)
reghdfe tr did pd oei is fdi egl cmc, absorb(year city_id)
est store mech2_tr
outreg2 mech2_tr using "mechanism2_results.docx", word append ctitle("Mechanism 2: Tax Revenue") keep(did) addtext(Controls, Y)

// 6.5 经济集聚水平 (eal)
reghdfe eal did pd oei is fdi egl cmc, absorb(year city_id)
est store mech2_eal
outreg2 mech2_eal using "mechanism2_results.docx", word append ctitle("Mechanism 2: Economic Agglomeration") keep(did) addtext(Controls, Y)

// ------------------------------------
// 7. 机制分析3 (Mechanism Analysis 3)
// ------------------------------------

// 7.1 土地出让收入 (ltr)
reghdfe ltr did pd oei is fdi egl cmc, absorb(year city_id)
est store mech3_ltr
outreg2 mech3_ltr using "mechanism3_results.docx", word replace ctitle("Mechanism 3: Land Transfer Revenue") keep(did) addtext(Controls, Y)

// 7.2 土地出让面积 (lta)
reghdfe lta did pd oei is fdi egl cmc, absorb(year city_id)
est store mech3_lta
outreg2 mech3_lta using "mechanism3_results.docx", word append ctitle("Mechanism 3: Land Transfer Area") keep(did) addtext(Controls, Y)

// 7.3 土地出让价格 (ltp)
reghdfe ltp did pd oei is fdi egl cmc, absorb(year city_id)
est store mech3_ltp
outreg2 mech3_ltp using "mechanism3_results.docx", word append ctitle("Mechanism 3: Land Transfer Price") keep(did) addtext(Controls, Y)

// 7.4 工业用地土地出让 + 区域异质性 (ilta)
reghdfe iltr did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
est store mech3_ilta_east
outreg2 mech3_ilta_east using "mechanism3_results.docx", word append ctitle("Mechanism 3: Industrial Land Transfer (East)") keep(did) addtext(Controls, Y)
reghdfe iltr did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
est store mech3_ilta_midwest
outreg2 mech3_ilta_midwest using "mechanism3_results.docx", word append ctitle("Mechanism 3: Industrial Land Transfer (Midwest)") keep(did) addtext(Controls, Y)

// 7.5 商业用地土地出让 + 区域异质性 (clta)
reghdfe cltr did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
est store mech3_clta_east
outreg2 mech3_clta_east using "mechanism3_results.docx", word append ctitle("Mechanism 3: Commercial Land Transfer (East)") keep(did) addtext(Controls, Y)
reghdfe cltr did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
est store mech3_clta_midwest
outreg2 mech3_clta_midwest using "mechanism3_results.docx", word append ctitle("Mechanism 3: Commercial Land Transfer (Midwest)") keep(did) addtext(Controls, Y)

// ------------------------------------
// 8. 机制分析3 + 异质性分析 (Mechanism 3 + Heterogeneity)
// ------------------------------------

// 8.1 财政收入质量 (frq)
// reghdfe debt did pd oei is fdi egl cmc frq, absorb(year city_id)
// est store mech3_frq
// outreg2 mech3_frq using "mechanism3_hetero_results.docx", word replace ctitle("Mech 3 Hetero: Fiscal Revenue Quality") keep(did frq) addtext(Controls, Y)

// // 8.2 财政收入压力 (fp) - 中位数分组 + 调节效应
// egen fp_median = median(fp)
//
// reghdfe debt did##c.ltr pd oei is fdi egl cmc if fp > fp_median, absorb(year city_id)
// est store mech3_fp_mod
// outreg2 mech3_fp_mod using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Fiscal Pressure Moderation") keep(did c.ltr did#c.ltr) addtext(Controls, Y)
//
// reghdfe debt did##c.ltr pd oei is fdi egl cmc if fp <= fp_median, absorb(year city_id)
// est store mech3_fp_mod
// outreg2 mech3_fp_mod using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Fiscal Pressure Moderation") keep(did c.ltr did#c.ltr) addtext(Controls, Y)


// 8.3 土地财政依赖度 (lfd) - 中位数分组 + 调节效应
// egen lfd_median = median(lfd)
// gen lfd_high = (lfd > lfd_median)
// gen lfd_low = (lfd <= lfd_median)
// reghdfe debt did pd oei is fdi egl cmc ltr if lfd_high == 1, absorb(year city_id)
// est store mech3_lfd_high
// outreg2 mech3_lfd_high using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: High Land Fiscal Dependence") keep(did ltr) addtext(Controls, Y)
// reghdfe debt did pd oei is fdi egl cmc ltr if lfd_low == 1, absorb(year city_id)
// est store mech3_lfd_low
// outreg2 mech3_lfd_low using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Low Land Fiscal Dependence") keep(did ltr) addtext(Controls, Y)
// reghdfe debt did##c.ltr pd oei is fdi egl cmc if lfd != ., absorb(year city_id)
// est store mech3_lfd_mod
// outreg2 mech3_lfd_mod using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Land Fiscal Dependence Moderation") keep(did c.ltr did#c.ltr) addtext(Controls, Y)

// 8.4 经济增长压力 (egp) - 中位数分组 + 调节效应
egen egp_median = median(egp)

reghdfe debt did##c.ltr pd oei is fdi egl cmc if egp > egp_median, absorb(year city_id)
est store mech3_egp_low
outreg2 mech3_egp_low using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Low Economic Growth Pressure") keep(did ltr) addtext(Controls, Y)

reghdfe debt did##c.ltr pd oei is fdi egl cmc if egp <= egp_median, absorb(year city_id)
est store mech3_egp_mod
outreg2 mech3_egp_mod using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Economic Growth Pressure Moderation") keep(did c.ltr did#c.ltr) addtext(Controls, Y)

// 8.5 经济增长软约束 (egcs) - 是否为1 + 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egcs == 1, absorb(year city_id)
est store mech3_egcs_low
outreg2 mech3_egcs_low using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: No Soft Economic Growth Constraint") keep(did ltr) addtext(Controls, Y)

reghdfe debt did##c.ltr pd oei is fdi egl cmc if egcs == 0, absorb(year city_id)
est store mech3_egcs_mod
outreg2 mech3_egcs_mod using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Soft Economic Growth Constraint Moderation") keep(did c.ltr did#c.ltr) addtext(Controls, Y)

// 8.6 经济增长硬约束 (egch) - 是否为1 + 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egch == 1, absorb(year city_id)
est store mech3_egch_low
outreg2 mech3_egch_low using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: No Hard Economic Growth Constraint") keep(did ltr) addtext(Controls, Y)

reghdfe debt did##c.ltr pd oei is fdi egl cmc if egch == 0, absorb(year city_id)
est store mech3_egch_mod
outreg2 mech3_egch_mod using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Hard Economic Growth Constraint Moderation") keep(did c.ltr did#c.ltr) addtext(Controls, Y)

// 8.7 新预算法 - 2014年前后 + 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if year < 2014, absorb(year city_id)
est store mech3_pre_2014
outreg2 mech3_pre_2014 using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Pre-New Budget Law (Before 2014)") keep(did ltr) addtext(Controls, Y)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if year >= 2014, absorb(year city_id)
est store mech3_post_2014
outreg2 mech3_post_2014 using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Post-New Budget Law (2014 and Later)") keep(did ltr) addtext(Controls, Y)

// 8.8 地区金融发展水平 (lfd) - 中位数分组 + 调节效应
egen lfd_fin_median = median(lfd)

reghdfe debt did##c.ltr pd oei is fdi egl cmc if lfd > lfd_fin_median, absorb(year city_id)
est store mech3_lfd_fin_high
outreg2 mech3_lfd_fin_high using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: High Financial Development Level") keep(did ltr) addtext(Controls, Y)

reghdfe debt did##c.ltr pd oei is fdi egl cmc if lfd <= lfd_fin_median, absorb(year city_id)
est store mech3_lfd_fin_low
outreg2 mech3_lfd_fin_low using "mechanism3_hetero_results.docx", word append ctitle("Mech 3 Hetero: Low Financial Development Level") keep(did ltr) addtext(Controls, Y)


// ------------------------------------
// 9. 保存数据
// ------------------------------------
save "毕业论文数据_分析后.dta", replace
