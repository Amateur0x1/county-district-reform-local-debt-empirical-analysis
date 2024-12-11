from lib import *
class DataTransform:
    def __init__(self, data):
        self.data = data

# 清理地级市经济增长目标数据表
def process_economic_target_data(output_file):
    # read data to get cities and years
    reader = ExcelReader(output_file)
    cities = Tools.clean_empty_data(reader.read_column('城市对应', '选中城市'))
    years = [2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019]

    # clean data in sheet '地级市经济增长目标数据'
    city_target_cleaner = DataCleaner(
        file_path=output_file,
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
def process_province_target_data(output_file):
    # read data to get cities and years
    reader = ExcelReader(output_file)
    provinces = list(dict.fromkeys(Tools.clean_empty_data(reader.read_column('市长', '省份'))))
    print(provinces)
    years = [2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019]

    # clean data in sheet '省级经济增长目标数据'
    province_target_cleaner = DataCleaner(
        file_path=output_file,
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

# 清理地方债务数据中的财政自给率
def process_debt_data(output_file):
    reader = ExcelReader(output_file)
    years = [2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019]
    reader.read_column('地方债务数据', '年份')

def main(input_file, output_file):
    Tools.copy_file(input_file, output_file)
    # process_economic_target_data(output_file)
    # process_province_target_data(output_file)

if __name__ == "__main__":
    input_file = "projects/data/data.xlsx"
    output_file = "projects/data/data_cleaning.xlsx"
    main(input_file, output_file)
