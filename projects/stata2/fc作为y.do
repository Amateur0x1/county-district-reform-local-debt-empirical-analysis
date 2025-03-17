// 设置本地语言环境为中文
set locale_ui zh_CN

// 设置工作目录（请将路径替换为您的实际数据路径）
cd "/Users/zhourongchang/project_cs/paper/毕业论文最终文件夹/county-district-reform-local-debt-empirical-analysis/projects/stata2"

// 加载数据
use "毕业论文数据.dta", clear

// 安装必要的 Stata 包（如果尚未安装，不覆盖已有版本）
// capture ssc install reghdfe
// capture ssc install outreg2
// capture ssc install psmatch2
// capture ssc install winsor2
// capture ssc install coefplot

// 数据准备：对变量进行缩尾处理
winsor2 debt fc, cut(1 99) // Winsorize: 移除 1% 和 99% 的极值
foreach var in debt {
    drop `var'
    rename `var'_w `var'
}


// 生成人口流入异质性变量
gen pi_inflow = (pi > 1)

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


// ------------------------------------
// 1. 基准回归 (Baseline Regression)
// ------------------------------------

// 1.1 debt 作为因变量
// 1.1.1 不加入控制变量
reghdfe debt did, absorb(year city_id)
est store debt_no_controls
outreg2 using "baseline_results.docx", word replace ctitle("Debt: No Controls") keep(did)

// 1.1.2 加入控制变量
reghdfe debt did pd oei is fdi egl cmc, absorb(year city_id)
est store debt_with_controls
outreg2 using "baseline_results.docx", word append ctitle("Debt: With Controls") keep(did pd oei is fdi egl cmc)

// 1.2 fc 作为因变量
// 1.2.1 不加入控制变量
reghdfe fc did, absorb(year city_id)
est store fc_no_controls
outreg2 using "baseline_results.docx", word append ctitle("FC: No Controls") keep(did)

// 1.2.2 加入控制变量
reghdfe fc did pd oei is fdi egl cmc, absorb(year city_id)
est store fc_with_controls
outreg2 using "baseline_results.docx", word append ctitle("FC: With Controls") keep(did pd oei is fdi egl cmc)

// ------------------------------------
// 2. 稳健性检验 (Robustness Checks)
// ------------------------------------

// 2.1 平行趋势检验
gen action = year - event_year
forvalues i = 13(-1)1 {
    gen pre_`i' = (action == -`i' & event_year != 0)
}
gen current = (action == 0 & event_year != 0)
forvalues j = 1(1)13 {
    gen las_`j' = (action == `j' & did == 1)
    replace las_`j' = 0 if las_`j' == .
}
// 2.1.1 debt 的平行趋势检验
xtreg debt pre_13 pre_12 pre_11 pre_10 pre_9 pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5 las_6 las_7 las_8 las_9 las_10 las_11 las_12 las_13 i.year, fe vce(cluster city_id)
est store parallel_trend_debt
coefplot, baselevels omitted keep(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) vertical recast(connect) ///
    order(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) ///
    yline(0, lp(solid) lc(black)) xline(6, lp(solid)) ///
    ytitle("政策效应") xtitle("政策时点") ///
    xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" 5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" 10 "4" 11 "5") ///
    ciopts(recast(rcap) lc(black) lp(dash) lw(thin)) scale(1.0)

// 2.1.2 fc 的平行趋势检验
xtreg fc pre_13 pre_12 pre_11 pre_10 pre_9 pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5 las_6 las_7 las_8 las_9 las_10 las_11 las_12 las_13 i.year, fe vce(cluster city_id)
est store parallel_trend_fc
coefplot, baselevels omitted keep(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) vertical recast(connect) ///
    order(pre_5 pre_4 pre_3 pre_2 pre_1 current las_1 las_2 las_3 las_4 las_5) ///
    yline(0, lp(solid) lc(black)) xline(6, lp(solid)) ///
    ytitle("政策效应") xtitle("政策时点") ///
    xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" 5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" 10 "4" 11 "5") ///
    ciopts(recast(rcap) lc(black) lp(dash) lw(thin)) scale(1.0)
// 2.2 PSM-DID
psmatch2 did pd oei is fdi egl cmc, outcome(debt) logit ate neighbor(4) caliper(0.05)
gen weight = _weight
// 2.2.1 debt 的 PSM-DID
reghdfe debt did if weight != ., absorb(year city_id)
est store psm_did_debt
outreg2 using "robustness_results.docx", word replace ctitle("PSM-DID: Debt") keep(did)
// 2.2.2 fc 的 PSM-DID
psmatch2 did pd oei is fdi egl cmc, outcome(fc) logit ate neighbor(4) caliper(0.05)
reghdfe fc did if weight != ., absorb(year city_id)
est store psm_did_fc
outreg2 using "robustness_results.docx", word append ctitle("PSM-DID: FC") keep(did)

// 2.3 安慰剂检验
set seed 1000
gen pseudo_did = runiform() > 0.5
// 2.3.1 debt 的安慰剂检验
reghdfe debt pseudo_did pd oei is fdi egl cmc, absorb(year city_id)
est store placebo_debt
outreg2 using "robustness_results.docx", word append ctitle("Placebo: Debt") keep(pseudo_did)
// 2.3.2 fc 的安慰剂检验
reghdfe fc pseudo_did pd oei is fdi egl cmc, absorb(year city_id)
est store placebo_fc
outreg2 using "robustness_results.docx", word append ctitle("Placebo: FC") keep(pseudo_did)

// 2.4 排除干扰政策
// 2.4.1 debt
reghdfe debt did pd oei is fdi egl cmc if county_to_city == 0, absorb(year city_id)
est store exclude_interference_debt
outreg2 using "robustness_results.docx", word append ctitle("Excluding Interference: Debt") keep(did)
// 2.4.2 fc
reghdfe fc did pd oei is fdi egl cmc if county_to_city == 0, absorb(year city_id)
est store exclude_interference_fc
outreg2 using "robustness_results.docx", word append ctitle("Excluding Interference: FC") keep(did)

// 2.5 排除副省级城市
// 2.5.1 debt
reghdfe debt did pd oei is fdi egl cmc if sub_provincial != 1, absorb(year city_id)
est store exclude_sub_provincial_debt
outreg2 using "robustness_results.docx", word append ctitle("Excluding Sub-Provincial: Debt") keep(did)
// 2.5.2 fc
reghdfe fc did pd oei is fdi egl cmc if sub_provincial != 1, absorb(year city_id)
est store exclude_sub_provincial_fc
outreg2 using "robustness_results.docx", word append ctitle("Excluding Sub-Provincial: FC") keep(did)

// 2.6 排除自治区
// 2.6.1 debt
reghdfe debt did pd oei is fdi egl cmc if autonomous_region == 0, absorb(year city_id)
est store exclude_autonomous_debt
outreg2 using "robustness_results.docx", word append ctitle("Excluding Autonomous Regions: Debt") keep(did)
// 2.6.2 fc
reghdfe fc did pd oei is fdi egl cmc if autonomous_region == 0, absorb(year city_id)
est store exclude_autonomous_fc
outreg2 using "robustness_results.docx", word append ctitle("Excluding Autonomous Regions: FC") keep(did)

// ------------------------------------
// 3. 异质性分析 (Heterogeneity Analysis)
// ------------------------------------

// 3.1 城市规模 (cs) - 中位数分组
summarize cs, detail
gen cs_high = cs > r(p50)
// 3.1.1 debt
reghdfe debt did pd oei is fdi egl cmc if cs_high == 1, absorb(year city_id)
est store hetero_cs_high_debt
outreg2 using "heterogeneity_results.docx", word replace ctitle("Heterogeneity: High CS - Debt") keep(did)
reghdfe debt did pd oei is fdi egl cmc if cs_high == 0, absorb(year city_id)
est store hetero_cs_low_debt
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Low CS - Debt") keep(did)
// 3.1.2 fc
reghdfe fc did pd oei is fdi egl cmc if cs_high == 1, absorb(year city_id)
est store hetero_cs_high_fc
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: High CS - FC") keep(did)
reghdfe fc did pd oei is fdi egl cmc if cs_high == 0, absorb(year city_id)
est store hetero_cs_low_fc
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Low CS - FC") keep(did)

// 3.2 人口集聚程度 (pad) - 中位数分组
summarize pad, detail
gen pad_high = pad > r(p50)
// 3.2.1 debt
reghdfe debt did pd oei is fdi egl cmc if pad_high == 1, absorb(year city_id)
est store hetero_pad_high_debt
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: High PAD - Debt") keep(did)
reghdfe debt did pd oei is fdi egl cmc if pad_high == 0, absorb(year city_id)
est store hetero_pad_low_debt
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Low PAD - Debt") keep(did)
// 3.2.2 fc
reghdfe fc did pd oei is fdi egl cmc if pad_high == 1, absorb(year city_id)
est store hetero_pad_high_fc
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: High PAD - FC") keep(did)
reghdfe fc did pd oei is fdi egl cmc if pad_high == 0, absorb(year city_id)
est store hetero_pad_low_fc
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Low PAD - FC") keep(did)

// 3.3 区域异质性 - 根据 region_type
// 3.3.1 debt
reghdfe debt did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
est store hetero_east_debt
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Eastern Region - Debt") keep(did)
reghdfe debt did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
est store hetero_midwest_debt
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Midwest Region - Debt") keep(did)
// 3.3.2 fc
reghdfe fc did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
est store hetero_east_fc
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Eastern Region - FC") keep(did)
reghdfe fc did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
est store hetero_midwest_fc
outreg2 using "heterogeneity_results.docx", word append ctitle("Heterogeneity: Midwest Region - FC") keep(did)

// ------------------------------------
// 4. 机制分析1 (Mechanism Analysis 1)
// ------------------------------------

// 4.1 土地资源配置效率1 (lrae)
reghdfe lrae did pd oei is fdi egl cmc, absorb(year city_id)
est store mechanism1_lrae
outreg2 using "mechanism1_results.docx", word replace ctitle("Mechanism1: lrae") keep(did)

// 4.2 土地资源配置效率2 (lrae2)
reghdfe lrae2 did pd oei is fdi egl cmc, absorb(year city_id)
est store mechanism1_lrae2
outreg2 using "mechanism1_results.docx", word append ctitle("Mechanism1: LRAE2") keep(did)

// ------------------------------------
// 5. 机制分析1 + 异质性 (Mechanism Analysis 1 with Heterogeneity)
// ------------------------------------

// 5.1 产业升级水平 (isu) - 中位数分组 + 调节效应
summarize isu, detail
gen isu_high = isu > r(p50)
// 5.1.1 lrae - 分组
reghdfe lrae did pd oei is fdi egl cmc if isu_high == 1, absorb(year city_id)
est store hetero_isu_high_lrae
outreg2 using "mechanism1_hetero_results.docx", word replace ctitle("Mechanism1 Hetero: High ISU - lrae") keep(did)
reghdfe lrae did pd oei is fdi egl cmc if isu_high == 0, absorb(year city_id)
est store hetero_isu_low_lrae
outreg2 using "mechanism1_hetero_results.docx", word append ctitle("Mechanism1 Hetero: Low ISU - lrae") keep(did)
// 5.1.2 lrae - 调节效应
reghdfe lrae did##c.isu pd oei is fdi egl cmc, absorb(year city_id)
est store hetero_isu_interaction_lrae
outreg2 using "mechanism1_hetero_results.docx", word append ctitle("Mechanism1 Hetero: ISU Interaction - lrae") keep(did c.isu did#c.isu)

// 5.2 人口流入异质性 (pi)
reghdfe lrae did pd oei is fdi egl cmc if pi_inflow == 1, absorb(year city_id)
est store hetero_pi_high_lrae
outreg2 using "mechanism1_hetero_results.docx", word append ctitle("Mechanism1 Hetero: High PI - lrae") keep(did)
reghdfe lrae did pd oei is fdi egl cmc if pi_inflow == 0, absorb(year city_id)
est store hetero_pi_low_lrae
outreg2 using "mechanism1_hetero_results.docx", word append ctitle("Mechanism1 Hetero: Low PI - lrae") keep(did)

// 5.3 多中心结构 (mc) - 中位数分组 + 调节效应
summarize mc, detail
gen mc_high = mc > r(p50)
// 5.3.1 lrae - 分组
reghdfe lrae did pd oei is fdi egl cmc if mc_high == 1, absorb(year city_id)
est store hetero_mc_high_lrae
outreg2 using "mechanism1_hetero_results.docx", word append ctitle("Mechanism1 Hetero: High MC - lrae") keep(did)
reghdfe lrae did pd oei is fdi egl cmc if mc_high == 0, absorb(year city_id)
est store hetero_mc_low_lrae
outreg2 using "mechanism1_hetero_results.docx", word append ctitle("Mechanism1 Hetero: Low MC - lrae") keep(did)
// 5.3.2 lrae - 调节效应
reghdfe lrae did##c.mc pd oei is fdi egl cmc, absorb(year city_id)
est store hetero_mc_interaction_lrae
outreg2 using "mechanism1_hetero_results.docx", word append ctitle("Mechanism1 Hetero: MC Interaction - lrae") keep(did c.mc did#c.mc)

// ------------------------------------
// 6. 机制分析2 (Mechanism Analysis 2)
// ------------------------------------

// 6.1 土地出让收入 (ltr)
reghdfe ltr did pd oei is fdi egl cmc, absorb(year city_id)
est store mechanism2_ltr
outreg2 using "mechanism2_results.docx", word replace ctitle("Mechanism2: LTR") keep(did)

// 6.2 土地出让面积 (lta)
reghdfe lta did pd oei is fdi egl cmc, absorb(year city_id)
est store mechanism2_lta
outreg2 using "mechanism2_results.docx", word append ctitle("Mechanism2: LTA") keep(did)

// 6.3 土地出让价格 (ltp)
reghdfe ltp did pd oei is fdi egl cmc, absorb(year city_id)
est store mechanism2_ltp
outreg2 using "mechanism2_results.docx", word append ctitle("Mechanism2: LTP") keep(did)

// 6.4 工业用地土地出让 - 区域异质性
// 6.4.1 ltr - 东部
reghdfe ltr did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
est store mechanism2_ltr_east
outreg2 using "mechanism2_results.docx", word append ctitle("Mechanism2: LTR - East") keep(did)
// 6.4.2 ltr - 中西部
reghdfe ltr did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
est store mechanism2_ltr_midwest
outreg2 using "mechanism2_results.docx", word append ctitle("Mechanism2: LTR - Midwest") keep(did)

// 6.5 商业用地土地出让 - 区域异质性（假设商业用地变量为 cltr, clta, cltp）
foreach var in cltr clta cltp {
    reghdfe `var' did pd oei is fdi egl cmc if region_type == 1, absorb(year city_id)
    est store mechanism2_`var'_east
    outreg2 using "mechanism2_results.docx", word append ctitle("Mechanism2: `var' - East") keep(did)
    reghdfe `var' did pd oei is fdi egl cmc if region_type == 2, absorb(year city_id)
    est store mechanism2_`var'_midwest
    outreg2 using "mechanism2_results.docx", word append ctitle("Mechanism2: `var' - Midwest") keep(did)
}

// ------------------------------------
// 7. 机制分析2 + 异质性 (Mechanism Analysis 2 with Heterogeneity)
// ------------------------------------

// 7.1 财政收入压力 (frp) - 中位数分组 + 调节效应
summarize frp, detail
gen frp_high = frp > r(p50)
// 7.1.1 debt - 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if frp_high == 1, absorb(year city_id)
est store mechanism2_frp_high_debt
outreg2 using "mechanism2_hetero_results.docx", word replace ctitle("Mechanism2 Hetero: High FRP - Debt") keep(did c.ltr did#c.ltr)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if frp_high == 0, absorb(year city_id)
est store mechanism2_frp_low_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low FRP - Debt") keep(did c.ltr did#c.ltr)
// 7.1.2 fc - 调节效应
reghdfe fc did##c.ltr pd oei is fdi egl cmc if frp_high == 1, absorb(year city_id)
est store mechanism2_frp_high_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: High FRP - FC") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if frp_high == 0, absorb(year city_id)
est store mechanism2_frp_low_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low FRP - FC") keep(did c.ltr did#c.ltr)

// 7.2 土地财政依赖度 (lfd) - 中位数分组 + 调节效应
summarize lfd, detail
gen lfd_high = lfd > r(p50)
// 7.2.1 debt - 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if lfd_high == 1, absorb(year city_id)
est store mechanism2_lfd_high_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: High LFD - Debt") keep(did c.ltr did#c.ltr)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if lfd_high == 0, absorb(year city_id)
est store mechanism2_lfd_low_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low LFD - Debt") keep(did c.ltr did#c.ltr)
// 7.2.2 fc - 调节效应
reghdfe fc did##c.ltr pd oei is fdi egl cmc if lfd_high == 1, absorb(year city_id)
est store mechanism2_lfd_high_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: High LFD - FC") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if lfd_high == 0, absorb(year city_id)
est store mechanism2_lfd_low_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low LFD - FC") keep(did c.ltr did#c.ltr)

// 7.3 经济增长压力 (egp) - 中位数分组 + 调节效应
summarize egp, detail
gen egp_high = egp > r(p50)
// 7.3.1 debt - 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egp_high == 1, absorb(year city_id)
est store mechanism2_egp_high_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: High EGP - Debt") keep(did c.ltr did#c.ltr)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egp_high == 0, absorb(year city_id)
est store mechanism2_egp_low_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low EGP - Debt") keep(did c.ltr did#c.ltr)
// 7.3.2 fc - 调节效应
reghdfe fc did##c.ltr pd oei is fdi egl cmc if egp_high == 1, absorb(year city_id)
est store mechanism2_egp_high_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: High EGP - FC") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if egp_high == 0, absorb(year city_id)
est store mechanism2_egp_low_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low EGP - FC") keep(did c.ltr did#c.ltr)

// 7.4 经济增长软约束 (egcs) - 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egcs == 1, absorb(year city_id)
est store mechanism2_egcs_1_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCS=1 - Debt") keep(did c.ltr did#c.ltr)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egcs == 0, absorb(year city_id)
est store mechanism2_egcs_0_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCS=0 - Debt") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if egcs == 1, absorb(year city_id)
est store mechanism2_egcs_1_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCS=1 - FC") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if egcs == 0, absorb(year city_id)
est store mechanism2_egcs_0_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCS=0 - FC") keep(did c.ltr did#c.ltr)

// 7.5 经济增长硬约束 (egch) - 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egch == 1, absorb(year city_id)
est store mechanism2_egch_1_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCH=1 - Debt") keep(did c.ltr did#c.ltr)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if egch == 0, absorb(year city_id)
est store mechanism2_egch_0_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCH=0 - Debt") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if egch == 1, absorb(year city_id)
est store mechanism2_egch_1_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCH=1 - FC") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if egch == 0, absorb(year city_id)
est store mechanism2_egch_0_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: EGCH=0 - FC") keep(did c.ltr did#c.ltr)

// 7.6 新预算法异质性 - 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if year < 2014, absorb(year city_id)
est store mechanism2_pre_2014_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Pre-2014 - Debt") keep(did c.ltr did#c.ltr)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if year >= 2014, absorb(year city_id)
est store mechanism2_post_2014_debt
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Post-2014 - Debt") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if year < 2014, absorb(year city_id)
est store mechanism2_pre_2014_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Pre-2014 - FC") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if year >= 2014, absorb(year city_id)
est store mechanism2_post_2014_fc
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Post-2014 - FC") keep(did c.ltr did#c.ltr)

// 7.7 地区金融发展水平 (lfd) - 中位数分组 + 调节效应
summarize lfd, detail
gen lfd_high_new = lfd > r(p50)
// 7.7.1 debt - 调节效应
reghdfe debt did##c.ltr pd oei is fdi egl cmc if lfd_high_new == 1, absorb(year city_id)
est store mechanism2_lfd_high_debt_new
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: High LFD - Debt") keep(did c.ltr did#c.ltr)
reghdfe debt did##c.ltr pd oei is fdi egl cmc if lfd_high_new == 0, absorb(year city_id)
est store mechanism2_lfd_low_debt_new
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low LFD - Debt") keep(did c.ltr did#c.ltr)
// 7.7.2 fc - 调节效应
reghdfe fc did##c.ltr pd oei is fdi egl cmc if lfd_high_new == 1, absorb(year city_id)
est store mechanism2_lfd_high_fc_new
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: High LFD - FC") keep(did c.ltr did#c.ltr)
reghdfe fc did##c.ltr pd oei is fdi egl cmc if lfd_high_new == 0, absorb(year city_id)
est store mechanism2_lfd_low_fc_new
outreg2 using "mechanism2_hetero_results.docx", word append ctitle("Mechanism2 Hetero: Low LFD - FC") keep(did c.ltr did#c.ltr)

// ------------------------------------
// 8. 保存结果
// ------------------------------------
save "毕业论文数据_分析后.dta", replace
