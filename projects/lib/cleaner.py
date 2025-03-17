import pandas as pd
from lib.tools import *
from functools import singledispatch
from dataclasses import dataclass
from typing import List, Optional
import numpy as np

@dataclass
class LongFormatParams:
    id_vars: List[str]
    value_vars: List[str]
    var_name: str
    value_name: str

class DataCleaner:
    """
    数据清洗类，用于处理数据中的缺失值和异常值
    
    参数:
        data: 可以是Excel文件路径或pandas DataFrame
        sheet_name: 如果data是文件路径，则需要指定sheet名称
    """
    def __init__(self, data, sheet_name: str = None, is_long_format: bool = True, long_format_params: Optional[LongFormatParams] = None):
        """
        初始化数据清洗类
        参数:
            data: pandas DataFrame或Excel文件路径
            sheet_name: 如果data是文件路径，则需要指定sheet名称
            is_long_format: 是否需要转换为长格式，默认为True
            long_format_params: 转换为长格式所需的参数
        """
        if isinstance(data, str):
            self.file_path = data
            self.sheet_name = sheet_name
            
            if sheet_name is None:
                raise ValueError("sheet_name must be provided when data is a file path")

            # 读取Excel文件
            excel_file = pd.ExcelFile(self.file_path)
            
            # 检查sheet是否存在
            if self.sheet_name not in excel_file.sheet_names:
                raise ValueError(f"Sheet '{self.sheet_name}' not found in file")

            # 读取数据
            self.data = pd.read_excel(self.file_path, sheet_name=self.sheet_name)
            if not is_long_format and long_format_params:
                self.data = Tools.panel_to_long(
                    self.data, 
                    long_format_params.id_vars, 
                    long_format_params.value_vars, 
                    long_format_params.var_name, 
                    long_format_params.value_name
                )
        elif isinstance(data, pd.DataFrame):
            self.data = data.copy()
        else:
            raise ValueError("data must be either a pandas DataFrame or a file path")

    @timeit
    def replace_column_name(self, column_names: list[str], new_column_name: str):
        print(self.data.columns)
        for column_name in column_names:
            if column_name in self.data.columns:
                self.data = self.data.rename(columns={column_name: new_column_name}, inplace=True)
                break

    @timeit
    def clean_column_data(self, column_name: str, replace_value: str) -> None:
        """
        根据指定的列名和替换值清理数据
        
        参数:
            column_name (str): 需要过滤的列名
            replace_value (str): 需要替换的值
        """
        self.data[column_name] = self.data[column_name].str.replace(replace_value, '')

    @timeit
    def clean_data_keep_values(self, column_name: str, keep_values: list) -> None:
        """
        根据指定的列名和保留值列表清理数据
        
        参数:
            column_name (str): 需要过滤的列名
            keep_values (list): 需要保留的值列表
            
        异常:
            ValueError: 当指定的列名不存在时抛出
        """
        
        if column_name not in self.data.columns:
            raise ValueError(f"列名 '{column_name}' 不存在")
        
        mask = self.data[column_name].isin(keep_values)
        self.data = self.data[mask].reset_index(drop=True)
        
    @timeit
    def rearrange_data(self, sort_priority: list[str], sort_orders: dict[str, list]) -> None:
        """
        对 Excel 表格数据按指定优先级和顺序进行排序，并覆盖写入到同一文件。

        参数:
            filename (str): Excel 文件路径
            sheet_name (str): 需要处理的 sheet 名称
            sort_priority (list[str]): 排序优先级列表，如 ['city', 'year']
            sort_orders (dict[str, list]): 各字段的具体排序顺序，
                                           如 {'city': ['北京', '上海'], 'year': [2018, 2019]}。
        
        返回:
            无，操作完成后文件被更新。
        """
        missing_columns = [field for field in sort_priority if field not in self.data.columns]
        if missing_columns:
            raise ValueError(f"以下字段在数据中不存在: {missing_columns}")
        
        for field in sort_priority:
            if field in sort_orders:
                self.data[field] = pd.Categorical(self.data[field], categories=sort_orders[field], ordered=True)

        self.data = self.data.sort_values(by=sort_priority).reset_index(drop=True)

    @timeit
    def interpolate_missing_data(self, y_column: str, id_column: str, x_column: str, 
                                treat_zeros_as_missing: bool = False,
                                replace_negative_with_nearest_positive: bool = False) -> None:
        """
        使用线性回归对缺失数据进行插值
        
        参数:
        y_column: 需要插值的列名
        id_column: 分组的ID列名（如城市）
        x_column: 自变量列名（如年份）
        treat_zeros_as_missing: 是否将0值视为缺失值
        replace_negative_with_nearest_positive: 是否将负值替换为最近年份的正值
        """
        # 验证列是否存在
        required_columns = [y_column, id_column, x_column]
        for col in required_columns:
            if col not in self.data.columns:
                raise ValueError(f"列 {col} 不存在于数据中")
        
        # 确保数据类型正确
        if not pd.api.types.is_numeric_dtype(self.data[y_column]):
            raise ValueError(f"列 {y_column} 必须是数值类型")
        
        # 创建一个副本以避免修改原始数据
        data = self.data.copy()
        
        # 如果需要将0值视为缺失值
        if treat_zeros_as_missing:
            # 将y_column中的0值替换为NaN
            data.loc[data[y_column] == 0, y_column] = np.nan
        
        # 获取唯一的分组值（如城市）
        groups = data[id_column].unique()
        
        # 对每个分组进行处理
        for group in groups:
            # 获取当前分组的数据
            group_data = data[data[id_column] == group].copy()
            
            # 如果当前分组的数据中y_column没有缺失值，则跳过
            if not group_data[y_column].isna().any():
                continue
            
            # 获取非缺失值的数据点
            valid_data = group_data.dropna(subset=[y_column])
            
            # 如果非缺失值数据点少于2个，则无法进行线性回归，跳过
            if len(valid_data) < 2:
                continue
            
            # 准备线性回归的数据
            X = valid_data[x_column].values
            y = valid_data[y_column].values
            
            # 使用numpy进行线性回归
            A = np.vstack([X, np.ones(len(X))]).T
            slope, intercept = np.linalg.lstsq(A, y, rcond=None)[0]
            
            # 获取缺失值的索引
            missing_indices = group_data[group_data[y_column].isna()].index
            
            # 对缺失值进行预测
            for idx in missing_indices:
                x_val = self.data.loc[idx, x_column]
                predicted_value = slope * x_val + intercept
                
                # 如果需要替换负值为最近年份的正值
                if replace_negative_with_nearest_positive and predicted_value < 0:
                    # 获取当前分组中所有正值数据
                    positive_data = valid_data[valid_data[y_column] > 0]
                    
                    if not positive_data.empty:
                        # 计算年份差异，找到最近的年份
                        positive_data['year_diff'] = abs(positive_data[x_column] - x_val)
                        nearest_idx = positive_data['year_diff'].idxmin()
                        nearest_positive = positive_data.loc[nearest_idx, y_column]
                        
                        # 用最近年份的正值替换预测的负值
                        self.data.loc[idx, y_column] = nearest_positive
                    else:
                        # 如果没有正值，则使用0
                        self.data.loc[idx, y_column] = 0
                else:
                    # 将预测值填充到原始数据中
                    self.data.loc[idx, y_column] = predicted_value

    @timeit
    def create_panel_dataset(self, index_columns: list[str], index_values: dict[str, list]) -> None:
        """
        创建面板数据集，确保包含所有可能的组合

        参数:
            index_columns (list[str]): 索引列名列表，如 ['地级市', '年份']
            index_values (dict[str, list]): 每个索引列的所有可能值，如 {'地级市': cities, '年份': years}
        """
        # 保存原始数据（包含改革信息）
        reform_data = self.data.copy()
        
        # 获取列名
        city_col = index_columns[0]  # '地级市'
        year_col = index_columns[1]  # '年份'
        
        # 获取城市和年份列表
        cities = index_values[city_col]
        years = sorted(index_values[year_col])  # 确保年份排序
        
        # 生成完整的面板数据（所有城市和年份的组合）
        panel_data = []
        for city in cities:
            for year in years:
                panel_data.append({city_col: city, year_col: year})
        
        # 转换为DataFrame
        panel_df = pd.DataFrame(panel_data)
        
        # 确保年份列为整数类型
        panel_df[year_col] = panel_df[year_col].astype(int)
        if year_col in reform_data.columns:
            reform_data[year_col] = pd.to_numeric(reform_data[year_col], errors='coerce').astype('Int64')
        
        # 合并面板数据和原始数据
        # 使用left join确保保留所有城市-年份组合，即使在原始数据中不存在
        self.data = pd.merge(panel_df, reform_data, on=index_columns, how='left')
        

        # 将缺失值填充为0或适当的默认值
        # 对于撤县设区数据，缺失值表示该年份未进行改革，应填充为0
        numeric_columns = self.data.select_dtypes(include=['int64', 'float64']).columns
        self.data[numeric_columns] = self.data[numeric_columns].fillna(0)
        
    @timeit
    def create_did_variable(self, time_col: str, unit_col: str) -> None:
        """
        创建DID变量及其组成部分
        - treat: 是否为改革城市（1表示该城市在研究期间发生过改革）
        - obi: 是否为改革后时期（1表示当前年份>=改革年份）
        - did: treat * obi 的乘积
        
        参数:
            time_col: 时间列名（年份）
            unit_col: 单位列名（地级市）
        """
        # 初始化变量
        self.data['treat'] = 0
        self.data['obi'] = 0
        self.data['did'] = 0
        
        # 获取每个城市的改革时间
        reform_data = self.data[self.data['省份'].notna()].copy()
        
        if not reform_data.empty:
            # 按城市分组，找出每个城市的改革年份
            reform_years = reform_data.groupby(unit_col)[time_col].min()
            
            # 对每个发生改革的城市
            for city, reform_year in reform_years.items():
                # 设置treat=1（表示该城市是改革城市）
                self.data.loc[self.data[unit_col] == city, 'treat'] = 1
                
                # 设置obi=1（表示改革年份及之后的时期）
                mask = (
                    (self.data[unit_col] == city) & 
                    (self.data[time_col] >= reform_year)
                )
                self.data.loc[mask, 'obi'] = 1
                
                # 计算did（treat和obi的乘积）
                self.data['did'] = self.data['treat'] * self.data['obi']
        
        # 使用const.py中的城市顺序进行排序
        from const import Constant
        city_order = pd.CategoricalDtype(categories=Constant.cities, ordered=True)
        self.data[unit_col] = self.data[unit_col].astype(city_order)
        self.data = self.data.sort_values(by=[unit_col, time_col])

    @timeit
    def replace_values_less_than_one(self, columns: List[str]) -> None:
        """
        将指定列中小于1的值替换为1
        
        参数:
            columns (List[str]): 需要处理的列名列表
        """
        for column in columns:
            if column not in self.data.columns:
                print(f"警告: 列 '{column}' 不存在于数据中")
                continue
                
            # 检查列是否为数值类型
            if not np.issubdtype(self.data[column].dtype, np.number):
                print(f"警告: 列 '{column}' 不是数值类型，跳过处理")
                continue
                
            # 将小于1的值替换为1
            mask = (self.data[column] < 1)  # 保留0值不变
            if mask.any():
                print(f"列 '{column}' 中有 {mask.sum()} 个小于1的值被替换为1")
                self.data.loc[mask, column] = 1
                
    @timeit
    def close_file_and_save(self):
        """
        将数据写回Excel文件并关闭
        """
        with pd.ExcelWriter(self.file_path, mode='a', if_sheet_exists='replace') as writer:
            self.data.to_excel(writer, sheet_name=self.sheet_name, index=False)
