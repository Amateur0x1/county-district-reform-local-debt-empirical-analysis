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
    数据清洗类，用于删除Excel文件中不在指定城市和年份范围内的数据
    
    参数:
        file_path (str): Excel文件路径
        sheet_name (str): 需要处理的sheet名称
    """
    def __init__(self, file_path: str, sheet_name: str, is_long_format: bool = True, long_format_params: Optional[LongFormatParams] = None):
        """
        初始化数据清洗类
        参数:
            file_path (str): Excel文件路径
            sheet_name (str): 需要处理的sheet名称
            is_long_format (bool): 是否需要转换为长格式，默认为True
            long_format_params (dict): 转换为长格式所需的参数字典，包含以下键值:
                - id_vars (list): 需要保留的标识列，如 ['province', 'city']
                - value_vars (list): 需要转换的数值列，如年份列表 [2018, 2019, 2020]
                - var_name (str): 转换后的变量名列名称，如 'year'
                - value_name (str): 转换后的数值列名称，如 'target'
        """
        self.file_path = file_path
        self.sheet_name = sheet_name

        # 读取Excel文件
        excel_file = pd.ExcelFile(self.file_path)
        
        # 检查sheet是否存在
        if self.sheet_name not in excel_file.sheet_names:
            raise ValueError(f"Sheet '{self.sheet_name}' not found in file")

        # 读取数据
        self.data = pd.read_excel(self.file_path, sheet_name=self.sheet_name)
        if not is_long_format:
            self.data = Tools.panel_to_long(self.data, long_format_params.id_vars, long_format_params.value_vars, long_format_params.var_name, long_format_params.value_name)

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
    def interpolate_missing_data(self, y_column: str, id_column: str, x_column: str) -> None:
        """
        对指定列中的缺失值进行插值处理，首尾使用线性回归，中间使用插值法
        
        参数:
            y_column (str): 需要插值的数值列名
            id_column (str): 分组ID列名(如城市或省份)
            x_column (str): 年份列名
            
        异常:
            ValueError: 当指定的列名不存在或数据类型不正确时抛出
        """
        # 验证列是否存在
        required_columns = [y_column, id_column, x_column]
        if not all(col in self.data.columns for col in required_columns):
            missing_cols = [col for col in required_columns if col not in self.data.columns]
            raise ValueError(f"以下列不存在: {missing_cols}")
            
        # 确保数据类型正确
        try:
            self.data[y_column] = pd.to_numeric(self.data[y_column])
            self.data[x_column] = pd.to_numeric(self.data[x_column])
        except ValueError:
            raise ValueError(f"列 '{y_column}' 或 '{x_column}' 包含非数值数据")
            
        # 按ID分组处理
        for group_id in self.data[id_column].unique():
            mask = self.data[id_column] == group_id
            group_data = self.data.loc[mask].copy()
            
            # 如果组内有缺失值才进行处理
            if group_data[y_column].isna().any():
                # 获取非缺失值的索引
                valid_idx = group_data[y_column].notna()
                years = group_data.loc[valid_idx, x_column].values
                values = group_data.loc[valid_idx, y_column].values
                
                if len(years) >= 2:  # 至少需要两个点才能进行线性回归
                    # 计算线性回归系数
                    coeffs = np.polyfit(years, values, 1)
                    
                    # 处理首尾缺失值
                    all_years = group_data[x_column].values
                    predicted_values = np.polyval(coeffs, all_years)
                    
                    # 对中间的缺失值进行插值
                    interpolated = pd.Series(predicted_values, index=group_data.index)
                    interpolated.loc[valid_idx] = values  # 保持原有的非缺失值不变
                    
                    # 对中间的缺失值使用分段插值
                    middle_values = interpolated.copy()
                    middle_values = middle_values.interpolate(method='linear')
                    
                    # 更新数据
                    self.data.loc[mask, y_column] = middle_values
                    
        # 处理完所有分组后，检查是否还有遗留的缺失值
        remaining_na = self.data[y_column].isna().sum()
        if remaining_na > 0:
            print(f"警告: 仍有 {remaining_na} 个缺失值无法通过插值处理")
        
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
        
        # 创建所有组合的面板数据，使用传入的列名
        # 获取每个索引列的值
        city_col = index_columns[0]
        year_col = index_columns[1]
        cities = index_values[city_col]
        years = sorted(index_values[year_col])  # 确保年份排序
        
        # 生成笛卡尔积
        panel_data = []
        for city in cities:
            for year in years:
                panel_data.append({city_col: city, year_col: year})
        
        # 转换为DataFrame并按列排序
        panel_df = pd.DataFrame(panel_data)
        panel_df = panel_df.sort_values(by=index_columns)
        
        # 合并时确保数据类型一致，例如年份转换为相同类型
        # 假设原始数据中的年份是整数，panel_df中的年份也应为整数
        panel_df[year_col] = panel_df[year_col].astype(int)
        reform_data[year_col] = reform_data[year_col].astype(int)
        
        # 合并面板数据和原始数据，左连接以保留所有组合
        self.data = pd.merge(panel_df, reform_data, on=index_columns, how='left')
        
    @timeit
    def create_did_variable(self, time_col: str, unit_col: str) -> None:
        """
        创建DID处理变量，确保列名正确引用
        """
        # 获取改革时间（非空的最小年份）
        reform_years = self.data.dropna(subset=['改革时间']).groupby(unit_col)['改革时间'].min().to_dict()
        
        # 创建DID变量
        self.data['did'] = 0  # 初始化为0
        # 根据改革时间更新did
        for city, reform_year in reform_years.items():
            mask = (self.data[unit_col] == city) & (self.data[time_col] >= reform_year)
            self.data.loc[mask, 'did'] = 1
        
        # 排序数据
        self.data = self.data.sort_values([unit_col, time_col])
        
    @timeit
    def close_file_and_save(self):
        """
        将数据写回Excel文件并关闭
        """
        with pd.ExcelWriter(self.file_path, mode='a', if_sheet_exists='replace') as writer:
            self.data.to_excel(writer, sheet_name=self.sheet_name, index=False)
