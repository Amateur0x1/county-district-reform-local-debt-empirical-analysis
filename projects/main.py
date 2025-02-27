from lib import *
from workflow import Workflow
from const import *

class DataTransform:
    def __init__(self, data):
        self.data = data

# 清理地级市经济增长目标数据表
def process_economic_target_data(file_name, cities, years):
    # clean data in sheet '地级市经济增长目标数据'
    city_target_cleaner = DataCleaner(
        file_path=file_name,
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
        file_path=file_name,
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
        file_path=file_name,
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
        file_path=file_name,
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
        file_path=file_name,
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
        file_path=file_name,
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

# 处理灯光数据
# deprecated
def process_light_data(file_name, cities, years):
    # clean data in sheet '灯光数据'
    light_cleaner = DataCleaner(
        file_path=file_name,
        sheet_name='灯光数据',
        is_long_format=False,
        long_format_params=LongFormatParams(
            id_vars=['CITY', 'PR','PR_ID', 'PR_TYPE', 'CITY_ID', 'CITY_TYPE'],
            value_vars=years,
            var_name='year',
            value_name='light'
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
        file_path=file_name,
        sheet_name='控制变量',
    )

    control_variable_cleaner.clean_column_data('city', '市')
    control_variable_cleaner.clean_data_keep_values('city', cities)
    control_variable_cleaner.clean_data_keep_values('year', years)

    control_variable_cleaner.rearrange_data(
        sort_priority=['city', 'year'],
        sort_orders={'city': cities, 'year': years}
    )

    # write data to sheet '控制变量'
    control_variable_cleaner.close_file_and_save()

# 处理财政支出与收入
def process_finance_expenditure_and_income_data(file_name, cities, years):
    # clean data in sheet '财政支出与收入'
    finance_expenditure_and_income_cleaner = DataCleaner(
        file_path=file_name,
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
        file_path=file_name,
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
        file_path=file_name,
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
        file_path=file_name,
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
        file_path=file_name,
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

def process_data(file_name):
    # process_economic_target_data(file_name, Constant.cities, Constant.years)
    # process_province_target_data(file_name, Constant.provinces, Constant.years)
    # process_debt_data(file_name, Constant.cities, Constant.years)
    # process_land_sale_income_data(file_name, Constant.cities, Constant.years)
    # process_mayor_data(file_name, Constant.cities, Constant.years)
    # process_commercial_bank_data(file_name, Constant.cities, Constant.years)
    # process_light_data(file_name, Constant.cities, Constant.years)
    # process_control_variable_data(file_name, Constant.cities, Constant.years)
    # process_county_to_district_data(file_name, Constant.cities, Constant.years)
    # process_finance_expenditure_and_income_data(file_name, Constant.cities, Constant.years)
    # process_administrative_power_data(file_name, Constant.cities, Constant.years)
    # process_finance_self_sufficiency_data(file_name, Constant.cities, Constant.years)
    # process_fixed_asset_investment_data(file_name, Constant.cities, Constant.years)
    process_county_to_district_data(file_name, Constant.cities, Constant.years)

def main(input_file, output_file):
    Tools.copy_file(input_file, output_file)
    process_data(output_file)

if __name__ == "__main__":
    input_file = "projects/data/data_copy.xlsx"
    output_file = "projects/data/data_cleaning.xlsx"
    main(input_file, output_file)
