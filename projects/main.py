from lib import *
from workflow import Workflow
from const import *
import pandas as pd
from const import Constant
from lib.csv_writer import CSVWriter

class DataTransform:
    def __init__(self, data):
        self.data = data

# 清理地级市经济增长目标数据表
def process_economic_target_data(file_name, cities, years):
    # clean data in sheet '地级市经济增长目标数据'
    city_target_cleaner = DataCleaner(
        file_name,
        sheet_name='地级市经济增长目标数据',
        is_long_format=False,
        long_format_params=LongFormatParams(
            id_vars=['province', 'city'],
            value_vars=years,
            var_name='year',
            value_name='target'
        )
    )

    city_target_cleaner.clean_column_data('city', '市')
    city_target_cleaner.clean_data_keep_values('city', cities)
    city_target_cleaner.clean_data_keep_values('year', years)
    
    city_target_cleaner.rearrange_data(
        sort_priority=['city', 'year'],
        sort_orders={'city': cities, 'year': years}
    )
    city_target_cleaner.close_file_and_save()

# 清理省级经济增长目标数据表
def process_province_target_data(file_name, provinces, years):
    # clean data in sheet '省级经济增长目标数据'
    province_target_cleaner = DataCleaner(
        file_name,
        sheet_name='省级经济增长目标数据',
        is_long_format=False,
        long_format_params=LongFormatParams(
            id_vars=['province'],
            value_vars=years,
            var_name='year',
            value_name='target'
        )
    )
    province_target_cleaner.clean_data_keep_values('province', provinces)
    province_target_cleaner.clean_data_keep_values('year', years)

    province_target_cleaner.rearrange_data(
        sort_priority=['province', 'year'],
        sort_orders={'province': provinces, 'year': years}
    )

    province_target_cleaner.close_file_and_save()

# 清理地方政府债务数据中的城投平台有息债务亿元
def process_debt_data(file_name, cities, years):
    # clean data in sheet '地级市经济增长目标数据'
    city_target_cleaner = DataCleaner(
        file_name,
        sheet_name='地方政府债务数据',
    )

    city_target_cleaner.clean_column_data('地级市', '市')
    city_target_cleaner.clean_data_keep_values('地级市', cities)
    city_target_cleaner.clean_data_keep_values('年份', years)

    city_target_cleaner.rearrange_data(
        sort_priority=['地级市', '年份'],
        sort_orders={'地级市': cities, '年份': years}
    )

    city_target_cleaner.interpolate_missing_data('财政自给率', '地级市', '年份')
    city_target_cleaner.interpolate_missing_data('城投平台有息债务亿元', '地级市', '年份')
    city_target_cleaner.interpolate_missing_data('GDP亿元', '地级市', '年份')

    # write data to sheet '地方债务数据'
    city_target_cleaner.close_file_and_save()

# 处理土地出让收入数据
def process_land_sale_income_data(file_name, cities, years):

    # clean data in sheet '土地出让收入'
    land_sale_income_cleaner = DataCleaner(
        file_name,
        sheet_name='土地出让收入',
    )

    land_sale_income_cleaner.clean_column_data('地区', '市')
    land_sale_income_cleaner.clean_data_keep_values('地区', cities)
    land_sale_income_cleaner.clean_data_keep_values('年份', years)

    land_sale_income_cleaner.rearrange_data(
        sort_priority=['地区', '年份'],
        sort_orders={'地区': cities, '年份': years}
    )

    # write data to sheet '土地出让收入'
    land_sale_income_cleaner.close_file_and_save()

# 处理市长数据
# deprecated
def process_mayor_data(file_name, cities, years):
    # clean data in sheet '市长'
    mayor_cleaner = DataCleaner(
        file_name,
        sheet_name='市长',
    )

    mayor_cleaner.clean_column_data('城市', '市')
    mayor_cleaner.clean_data_keep_values('城市', cities)
    mayor_cleaner.clean_data_keep_values('年份', years)

    mayor_cleaner.rearrange_data(
        sort_priority=['城市', '年份'],
        sort_orders={'城市': cities, '年份': years}
    )

    # write data to sheet '市长'
    mayor_cleaner.close_file_and_save()

# 处理商业银行数据
# deprecated
def process_commercial_bank_data(file_name, cities, years):
    # clean data in sheet '商业银行'
    commercial_bank_cleaner = DataCleaner(
        file_name,
        sheet_name='商业银行数据',
    )

    commercial_bank_cleaner.clean_column_data('城市', '市')
    commercial_bank_cleaner.clean_data_keep_values('城市', cities)
    commercial_bank_cleaner.clean_data_keep_values('year', years)

    commercial_bank_cleaner.rearrange_data(
        sort_priority=['城市', 'year'],
        sort_orders={'城市': cities, 'year': years}
    )

    commercial_bank_cleaner.interpolate_missing_data('贷款总额亿元', '城市', 'year')

    # write data to sheet '商业银行'
    commercial_bank_cleaner.close_file_and_save()

# 处理灯光平均数据
def process_light_average_data(file_name, cities, years):
    # clean data in sheet '灯光数据'
    light_cleaner = DataCleaner(
        file_name,
        sheet_name='灯光平均数据',
        is_long_format=False,
        long_format_params=LongFormatParams(
            id_vars=['CITY', 'PR','PR_ID', 'PR_TYPE', 'CITY_ID', 'CITY_TYPE'],
            value_vars=years,
            var_name='year',
            value_name='light_average'
        )
    )

    light_cleaner.clean_column_data('CITY', '市')
    light_cleaner.clean_data_keep_values('CITY', cities)
    light_cleaner.clean_data_keep_values('year', years)

    light_cleaner.rearrange_data(
        sort_priority=['CITY', 'year'],
        sort_orders={'CITY': cities, 'year': years}
    )

    # write data to sheet '灯光数据'
    light_cleaner.close_file_and_save()


# 处理灯光总和数据
def process_light_sum_data(file_name, cities, years):
    # clean data in sheet '灯光数据'
    light_cleaner = DataCleaner(
        file_name,
        sheet_name='灯光总和数据',
        is_long_format=False,
        long_format_params=LongFormatParams(
            id_vars=['CITY', 'PR','PR_ID', 'PR_TYPE', 'CITY_ID', 'CITY_TYPE'],
            value_vars=years,
            var_name='year',
            value_name='light_sum'
        )
    )

    light_cleaner.clean_column_data('CITY', '市')
    light_cleaner.clean_data_keep_values('CITY', cities)
    light_cleaner.clean_data_keep_values('year', years)

    light_cleaner.rearrange_data(
        sort_priority=['CITY', 'year'],
        sort_orders={'CITY': cities, 'year': years}
    )

    # write data to sheet '灯光数据'
    light_cleaner.close_file_and_save()


# 处理控制变量
# deprecated
def process_control_variable_data(file_name, cities, years):
    # clean data in sheet '控制变量'
    control_variable_cleaner = DataCleaner(
        file_name,
        sheet_name='控制变量',
    )

    control_variable_cleaner.clean_column_data('city', '市')
    control_variable_cleaner.clean_data_keep_values('city', cities)
    control_variable_cleaner.clean_data_keep_values('year', years)

    control_variable_cleaner.rearrange_data(
        sort_priority=['city', 'year'],
        sort_orders={'city': cities, 'year': years}
    )

    # 对所有数值列进行插值处理
    numeric_columns = [col for col in control_variable_cleaner.data.columns if col not in ['city', 'year', '所属省份']]
    
    for column in numeric_columns:
        control_variable_cleaner.interpolate_missing_data(column, 'city', 'year')


    # write data to sheet '控制变量'
    control_variable_cleaner.close_file_and_save()

# 处理财政支出与收入
def process_finance_expenditure_and_income_data(file_name, cities, years):
    # clean data in sheet '财政支出与收入'
    finance_expenditure_and_income_cleaner = DataCleaner(
        file_name,
        sheet_name='财政支出与收入',
    )

    finance_expenditure_and_income_cleaner.clean_column_data('地区', '市')
    finance_expenditure_and_income_cleaner.clean_data_keep_values('地区', cities)
    finance_expenditure_and_income_cleaner.clean_data_keep_values('年份', years)

    finance_expenditure_and_income_cleaner.rearrange_data(
        sort_priority=['地区', '年份'],
        sort_orders={'地区': cities, '年份': years}
    )

    # write data to sheet '财政支出与收入'
    finance_expenditure_and_income_cleaner.close_file_and_save()

# 处理行政力量数据
# deprecated
def process_administrative_power_data(file_name, cities, years):
    # clean data in sheet '行政力量数据'
    administrative_power_cleaner = DataCleaner(
        file_name,
        sheet_name='行政力量数据',
    )

    administrative_power_cleaner.clean_column_data('city', '市')
    administrative_power_cleaner.clean_data_keep_values('city', cities)
    administrative_power_cleaner.clean_data_keep_values('year', years)

    administrative_power_cleaner.rearrange_data(
        sort_priority=['city', 'year'],
        sort_orders={'city': cities, 'year': years}
    )

    # write data to sheet '行政力量数据'
    administrative_power_cleaner.close_file_and_save()

# 处理财政自给率
def process_finance_self_sufficiency_data(file_name, cities, years):
    # clean data in sheet '财政自给率'
    finance_self_sufficiency_cleaner = DataCleaner(
        file_name,
        sheet_name='财政自给率',
    )

    finance_self_sufficiency_cleaner.clean_column_data('地级市', '市')
    finance_self_sufficiency_cleaner.clean_data_keep_values('地级市', cities)
    finance_self_sufficiency_cleaner.clean_data_keep_values('年份', years)

    finance_self_sufficiency_cleaner.rearrange_data(
        sort_priority=['地级市', '年份'],
        sort_orders={'地级市': cities, '年份': years}
    )

    # write data to sheet '财政自给率'
    finance_self_sufficiency_cleaner.close_file_and_save()

# 处理固定资产投资存量与增量 deprecated
def process_fixed_asset_investment_data(file_name, cities, years):
    # clean data in sheet '固定资产投资存量与增量'
    fixed_asset_investment_cleaner = DataCleaner(
        file_name,
        sheet_name='固定资产投资存量与增量',
    )

    fixed_asset_investment_cleaner.clean_column_data('城市', '市')
    fixed_asset_investment_cleaner.clean_data_keep_values('城市', cities)
    fixed_asset_investment_cleaner.clean_data_keep_values('年份', years)
    
    fixed_asset_investment_cleaner.rearrange_data(
        sort_priority=['城市', '年份'],
        sort_orders={'城市': cities, '年份': years}
    )
    
    # write data to sheet '固定资产投资存量与增量'
    fixed_asset_investment_cleaner.close_file_and_save()

# 处理撤县设区数据
def process_county_to_district_data(file_name, cities, years):
    # 首先创建完整的面板数据框架
    panel_data = []
    # 使用cities列表的原始顺序
    for city in cities:
        for year in sorted(years):  # 确保年份排序
            panel_data.append({
                '地级市': city,  # 直接使用const.py中的城市名
                '年份': year
            })
    
    # 转换为DataFrame，不需要额外排序，因为我们已经按照所需的顺序创建了数据
    panel_df = pd.DataFrame(panel_data)
    
    # 读取和清理撤县设区数据
    county_to_district_cleaner = DataCleaner(
        file_name,
        sheet_name='撤县设区数据',
    )

    # 清理数据
    county_to_district_cleaner.clean_column_data('地级市', '市')
    county_to_district_cleaner.clean_data_keep_values('地级市', cities)
    county_to_district_cleaner.clean_data_keep_values('年份', years)
    
    # 将清理后的数据与面板数据合并
    reform_data = county_to_district_cleaner.data
    
    # 确保年份列为整数类型
    panel_df['年份'] = panel_df['年份'].astype(int)
    reform_data['年份'] = pd.to_numeric(reform_data['年份'], errors='coerce').astype('Int64')
    
    # 合并数据
    merged_data = pd.merge(panel_df, reform_data, on=['地级市', '年份'], how='left')
    
    # 将缺失值填充为0
    numeric_columns = merged_data.select_dtypes(include=['int64', 'float64']).columns
    merged_data[numeric_columns] = merged_data[numeric_columns].fillna(0)
    
    # 更新清理器中的数据
    county_to_district_cleaner.data = merged_data
    
    # 创建DID变量
    county_to_district_cleaner.create_did_variable('年份', '地级市')
    
    # 保存数据
    county_to_district_cleaner.close_file_and_save()

# 处理城市建设支出数据
def process_city_expenditure_data(file_name, cities, years):
    # 首先创建完整的面板数据框架
    panel_data = []
    # 使用cities列表的原始顺序
    for city in cities:
        for year in sorted(years):  # 确保年份排序
            panel_data.append({
                '地区': city,
                '年份': year
            })
    
    # 转换为DataFrame，不需要额外排序，因为我们已经按照所需的顺序创建了数据
    panel_df = pd.DataFrame(panel_data)
    
    # 读取和清理城市建设支出数据
    city_expenditure_cleaner = DataCleaner(
        file_name,
        sheet_name='城建数据',
    )

    # 清理数据
    city_expenditure_cleaner.clean_column_data('地区', '市')
    city_expenditure_cleaner.clean_data_keep_values('地区', cities)
    city_expenditure_cleaner.clean_data_keep_values('年份', years)
    
    # 将清理后的数据与面板数据合并
    reform_data = city_expenditure_cleaner.data
    
    # 确保年份列为整数类型
    panel_df['年份'] = panel_df['年份'].astype(int)
    reform_data['年份'] = pd.to_numeric(reform_data['年份'], errors='coerce').astype('Int64')
    
    # 合并数据
    merged_data = pd.merge(panel_df, reform_data, on=['地区', '年份'], how='left')
    
    # 将缺失值填充为0
    numeric_columns = merged_data.select_dtypes(include=['int64', 'float64']).columns
    merged_data[numeric_columns] = merged_data[numeric_columns].fillna(0)
    
    # 更新清理器中的数据
    city_expenditure_cleaner.data = merged_data
    
    # 保存数据
    city_expenditure_cleaner.close_file_and_save()

# 融资成本数据
def process_finance_cost_data(file_name, cities, years):
    # 首先创建完整的面板数据框架
    panel_data = []
    # 使用cities列表的原始顺序
    for city in cities:
        for year in sorted(years):  # 确保年份排序
            panel_data.append({
                'City': city,
                'year': year
            })
    
    # 转换为DataFrame，不需要额外排序，因为我们已经按照所需的顺序创建了数据
    panel_df = pd.DataFrame(panel_data)
    
    # 读取和清理融资成本数据
    finance_cost_cleaner = DataCleaner(
        file_name,
        sheet_name='融资成本数据',
    )

    # 清理数据
    finance_cost_cleaner.clean_column_data('City', '市')
    finance_cost_cleaner.clean_data_keep_values('City', cities)
    finance_cost_cleaner.clean_data_keep_values('year', years)
    
    # 将清理后的数据与面板数据合并
    reform_data = finance_cost_cleaner.data
    
    # 确保年份列为整数类型
    panel_df['year'] = panel_df['year'].astype(int)
    reform_data['year'] = pd.to_numeric(reform_data['year'], errors='coerce').astype('Int64')
    
    # 合并数据
    merged_data = pd.merge(panel_df, reform_data, on=['City', 'year'], how='left')
    
    # 将缺失值填充为0
    numeric_columns = merged_data.select_dtypes(include=['int64', 'float64']).columns
    merged_data[numeric_columns] = merged_data[numeric_columns].fillna(0)
    
    # 更新清理器中的数据
    finance_cost_cleaner.data = merged_data
    
    # 保存数据
    finance_cost_cleaner.close_file_and_save()

def process_data(file_name):
    # process_economic_target_data(file_name, Constant.cities, Constant.years)
    # process_province_target_data(file_name, Constant.provinces, Constant.years)
    # process_debt_data(file_name, Constant.cities, Constant.years)
    # process_land_sale_income_data(file_name, Constant.cities, Constant.years)
    # process_mayor_data(file_name, Constant.cities, Constant.years)
    # process_commercial_bank_data(file_name, Constant.cities, Constant.years)
    process_light_average_data(file_name, Constant.cities, Constant.years)
    process_light_sum_data(file_name, Constant.cities, Constant.years)
    # process_control_variable_data(file_name, Constant.cities, Constant.years)
    # process_finance_expenditure_and_income_data(file_name, Constant.cities, Constant.years)
    # process_administrative_power_data(file_name, Constant.cities, Constant.years)
    # process_finance_self_sufficiency_data(file_name, Constant.cities, Constant.years)
    # process_fixed_asset_investment_data(file_name, Constant.cities, Constant.years)
    # process_county_to_district_data(file_name, Constant.cities, Constant.years)
    # process_city_expenditure_data(file_name, Constant.cities, Constant.years)
    # process_finance_cost_data(file_name, Constant.cities, Constant.years)

# 土地出让数据
def process_land_sale_data():
    input_file = "projects/data/土地出让true.csv"
    output_file = "projects/data/output_土地出让true.csv"
    
    # Read input CSV file
    df = pd.read_csv(input_file, low_memory=False)
    
    # 首先打印列名和唯一值，方便调试
    print("CSV文件的列名:", df.columns.tolist())
    print("\n供地方式的唯一值:")
    print(df['供地方式'].unique())
    print("\n土地用途的唯一值:")
    print(df['土地用途'].unique())
    print("\n土地来源的唯一值:")
    print(df['土地来源'].unique())
    
    # 处理城市名称，删除末尾的市字
    df['市'] = df['市'].str.replace('市$', '', regex=True)
    
    # 过滤数据，只保留有效的城市和年份
    df = df[df['市'].isin(Constant.cities) & df['年份'].isin(Constant.years)]
    
    # 只保留以"区"结尾的县域数据，过滤掉以"县"或"市"结尾的
    df = df.dropna(subset=['县'])  # 删除县列中的NaN值
    df = df[df['县'].str.endswith('区')]
    
    # 保留需要的列
    keep_columns = ['年份', '省', '省代码', '市', '市代码',
                   '供地总面积_公顷', '供地方式', '土地用途', '成交价格_万元', '土地来源']
    df = df[keep_columns]
    
    # 将数值列转换为数值类型
    df['年份'] = pd.to_numeric(df['年份'], errors='coerce')
    df['供地总面积_公顷'] = pd.to_numeric(df['供地总面积_公顷'], errors='coerce')
    df['成交价格_万元'] = pd.to_numeric(df['成交价格_万元'], errors='coerce')
    
    # 1. 处理供地方式
    supply_type_pivot = pd.pivot_table(
        df,
        values='供地总面积_公顷',
        index=['市', '年份'],
        columns=['供地方式'],
        aggfunc='sum',
        fill_value=0
    )
    supply_type_pivot = supply_type_pivot.add_prefix('供地方式_')
    
    # 2. 处理土地用途
    land_use_pivot = pd.pivot_table(
        df,
        values='供地总面积_公顷',
        index=['市', '年份'],
        columns=['土地用途'],
        aggfunc='sum',
        fill_value=0
    )
    land_use_pivot = land_use_pivot.add_prefix('土地用途_')
    
    # 3. 处理土地来源
    land_source_pivot = pd.pivot_table(
        df,
        values='供地总面积_公顷',
        index=['市', '年份'],
        columns=['土地来源'],
        aggfunc='sum',
        fill_value=0
    )
    land_source_pivot = land_source_pivot.add_prefix('土地来源_')
    
    # 将所有NaN值替换为0
    supply_type_pivot = supply_type_pivot.fillna(0)
    land_use_pivot = land_use_pivot.fillna(0)
    land_source_pivot = land_source_pivot.fillna(0)
    
    # 4. 计算总面积和加权平均价格
    # 使用更简单的方法计算加权平均价格
    # 首先计算每个分组的总面积和总价格
    agg_df = df.groupby(['市', '年份'], observed=True).agg({
        '供地总面积_公顷': 'sum',
        '成交价格_万元': 'sum'
    })
    
    # 添加一个新列计算平均价格
    agg_df['平均价格_万元每公顷'] = (agg_df['成交价格_万元'] / agg_df['供地总面积_公顷']).replace([np.inf, -np.inf], 0).fillna(0).round(2)
    
    # 将NaN替换为0
    agg_df = agg_df.fillna(0)
    
    # 合并所有数据
    result = pd.concat([agg_df, supply_type_pivot, land_use_pivot, land_source_pivot], axis=1)
    result = result.reset_index()
    
    # 使用 Constant.cities 的顺序进行排序
    result['市'] = pd.Categorical(result['市'], categories=Constant.cities, ordered=True)
    result = result.sort_values(by=['市', '年份'])
    
    # 计算每个城市的观测数据数量并过滤
    city_counts = result.groupby('市', observed=True).size()
    valid_cities = city_counts[city_counts > 10].index
    result = result[result['市'].isin(valid_cities)]
    
    # 创建完整的城市-年份组合
    city_year_combinations = pd.MultiIndex.from_product(
        [valid_cities, Constant.years],
        names=['市', '年份']
    )
    
    # 重建索引以包含所有可能的城市-年份组合
    result = result.set_index(['市', '年份'])
    result = result.reindex(city_year_combinations)
    result = result.reset_index()
    
    # 处理缺失值
    cleaner = DataCleaner(result)  # 现在可以直接传入DataFrame
    numeric_columns = ['供地总面积_公顷', '成交价格_万元', '平均价格_万元每公顷'] + \
                     [col for col in result.columns if col.startswith(('供地方式_', '土地用途_', '土地来源_'))]
    
    for column in numeric_columns:
        cleaner.interpolate_missing_data(column, '市', '年份')
    
    result = cleaner.data
    
    # 只对数值列进行0填充，保持分类列不变
    numeric_columns = result.select_dtypes(include=['float64', 'int64']).columns
    result[numeric_columns] = result[numeric_columns].fillna(0)
    
    # 将小于1的值替换为1
    cleaner = DataCleaner(result)
    cleaner.replace_values_less_than_one(numeric_columns.tolist())
    result = cleaner.data
    
    # Write to output file using CSVWriter
    writer = CSVWriter(output_file)
    writer.set_columns(result.columns.tolist())
    
    for _, row in result.iterrows():
        writer.add_row(row.to_dict())
    
    writer.write()
    
    # 打印最终的列名，方便检查
    print("\n最终数据的列名:")
    print(result.columns.tolist())

# 处理回归数据
def process_regression_data():
    input_file = "projects/data/会总数据.xlsx"
    output_file = "projects/data/会总数据clean.xlsx"
    Tools.copy_file(input_file, output_file)

    regression_cleaner = DataCleaner(
        output_file,
        sheet_name='回归数据',
    )

    autonomous_region_cities = [
    # 广西壮族自治区
    "南宁", "柳州", "桂林", "梧州", "北海", "防城港", "钦州", "贵港", "玉林", "百色", "贺州", "河池", "来宾", "崇左",
    
    # 内蒙古自治区
    "呼和浩特", "包头", "乌海", "赤峰", "通辽", "鄂尔多斯", "呼伦贝尔", "巴彦淖尔", "乌兰察布", "兴安盟", "锡林郭勒盟", "阿拉善盟",
    
    # 宁夏回族自治区
    "银川", "石嘴山", "吴忠", "固原", "中卫",
    
    # 新疆维吾尔自治区
    "乌鲁木齐", "克拉玛依", "吐鲁番", "哈密", "昌吉", "博尔塔拉", "巴音郭楞", "阿克苏", "克孜勒苏", "喀什", "和田", "伊犁", "塔城", "阿勒泰",
    
    # 西藏自治区
    "拉萨", "日喀则", "昌都", "林芝", "山南", "那曲", "阿里"
    ]

    # 副省级城市和省会城市列表（按地理大区排序）
    sub_provincial_cities = [
        # 华北地区
        "北京", "天津", "石家庄", "太原",
        
        # 东北地区
        "沈阳", "大连", "长春", "哈尔滨",
        
        # 华东地区
        "上海", "南京", "杭州", "合肥", "福州", "南昌", "济南", "青岛", "宁波", "厦门",
        
        # 华中地区
        "郑州", "武汉", "长沙",
        
        # 华南地区
        "广州", "深圳", "海口",
        
        # 西南地区
        "重庆", "成都", "贵阳", "昆明",
        
        # 西北地区
        "西安", "兰州", "西宁"
    ]

    # 部分撤县设市城市列表（按地区排序）
    di_jishi_list = [
        "九江", "合肥", "铜仁",
        "海东", "昌都", "日喀则", "咸阳", "南通", "荆门", "朔州", "唐山",
        "安庆", "滨州", "昭通", "平凉", "黑河", "宣城", "芜湖", "邵阳",
        "遂宁", "延安", "新乡", "温州", "玉溪", "赣州", "荆州", "安康",
        "永州"
    ]

    def get_city_type(city_name):
        """
        获取城市类型标识
        Args:
            city_name: 城市名称，可以带"市"也可以不带
        Returns:
            dict: 包含三个标识的字典
        """
        # 去除"市"后缀进行匹配
        city = city_name.replace("市", "")
        
        # 初始化结果
        result = {
            "autonomous_region": 0,  # 自治区城市
            "sub_provincial": 0,     # 副省级和省会城市
            "county_to_city": 0      # 地级市（撤县设市）
        }
        
        # 检查是否为自治区城市
        if city in autonomous_region_cities:
            result["autonomous_region"] = 1
            
        # 检查是否为副省级或省会城市
        if city in sub_provincial_cities:
            result["sub_provincial"] = 1
            
        # 检查是否为撤县设市
        if city_name in di_jishi_list:
            result["county_to_city"] = 1
            
        return result

    # 获取当前数据中的所有城市
    cities = regression_cleaner.data['city'].unique()
    
    # 创建一个字典存储每个城市的首次撤并年份和 action 标识
    event_years = {}
    
    # 对每个城市，找出 did 首次为 1 的年份
    for city in cities:
        city_data = regression_cleaner.data[regression_cleaner.data['city'] == city]
        # 找出 did 为 1 的年份，如果存在则取最小年份
        did_years = city_data[city_data['did'] == 1]['year']
        if not did_years.empty:
            event_years[city] = did_years.min()
        else:
            event_years[city] = 0  # 如果没有撤并事件，设为 0
         
    
    # 将事件年份添加到数据中
    regression_cleaner.data['event_year'] = regression_cleaner.data['city'].map(event_years)
    
    # 处理每个城市的类型标识
    city_types_list = []
    for city in cities:
        city_type = get_city_type(city)
        city_types_list.append({
            'city': city,
            'autonomous_region': city_type['autonomous_region'],
            'sub_provincial': city_type['sub_provincial'],
            'county_to_city': city_type['county_to_city']
        })
    
    # 将城市类型数据转换为DataFrame
    city_types_df = pd.DataFrame(city_types_list)
    
    # 将城市类型数据与原始数据合并
    regression_cleaner.data = regression_cleaner.data.merge(
        city_types_df,
        on='city',
        how='left'
    )
    
    # 保存处理后的数据
    regression_cleaner.close_file_and_save()

def main(input_file, output_file):
    Tools.copy_file(input_file, output_file)
    process_data(output_file)
    # process_land_sale_data()
    # process_regression_data()

if __name__ == "__main__":
    input_file = "projects/data/data_copy.xlsx"
    output_file = "projects/data/data_cleaning.xlsx"
    main(input_file, output_file)
