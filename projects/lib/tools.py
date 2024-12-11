import pandas as pd
from lib.const import Constant
import shutil
import time
from functools import wraps

def timeit(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()  # 记录开始时间
        result = func(*args, **kwargs)
        end_time = time.time()  # 记录结束时间
        elapsed_time = end_time - start_time
        print(f"Function {func.__name__} executed in {elapsed_time:.4f} seconds")
        return result
    return wrapper

class Tools:
    def __init__(self, file_path):
        self.file_path = file_path

    @staticmethod
    def is_same_city(city1: str, city2: str) -> bool:
        city1 = city1.strip().lower()
        city2 = city2.strip().lower()

        if city1 == city2:
            return True

        city1 = city1.replace('市', '')
        city2 = city2.replace('市', '')
        return city1 == city2

    @staticmethod
    def get_first_valid_column(filename: str, sheetname: str, column_list: list[str]) -> str:
        """
        返回Excel文件中指定sheet的DataFrame中第一个在给定列表中存在的列名
        
        参数:
            filename (str): Excel文件路径
            sheetname (str): sheet名称
            column_list (list[str]): 列名列表
            
        返回:
            str: 第一个匹配的列名，如果没有匹配则返回空字符串
        """
        df = pd.read_excel(filename, sheet_name=sheetname)
        for col in column_list:
            if col in df.columns:
                return col
        return ""
    
    @staticmethod
    def clean_column_data(filename: str, sheetname: str, column_name: str, remove_str: str) -> None:
        """
        对Excel文件中指定列的所有数据去掉指定字符串
        
        参数:
            filename (str): Excel文件路径
            sheetname (str): sheet名称
            column_name (str): 需要处理的列名
            remove_str (str): 需要去掉的字符串
        """
        # 读取数据
        df = pd.read_excel(filename, sheet_name=sheetname)
        
        # 检查列是否存在
        if column_name not in df.columns:
            raise ValueError(f"Column '{column_name}' not found in sheet")
            
        # 对指定列的数据去掉指定字符串
        df[column_name] = df[column_name].astype(str).apply(lambda x: x.replace(remove_str, ''))
        
        # 写回Excel文件
        with pd.ExcelWriter(filename, mode='a', if_sheet_exists='replace') as writer:
            df.to_excel(writer, sheet_name=sheetname, index=False)

    @staticmethod
    def rearrange_data(filename: str, sheet_name: str, sort_priority: list[str], sort_orders: dict[str, list]) -> None:
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
        try:
            # 读取 Excel 数据
            data = pd.read_excel(filename, sheet_name=sheet_name)
        except Exception as e:
            raise ValueError(f"读取 Excel 文件失败: {e}")

        # 检查排序字段是否存在于数据中
        missing_columns = [field for field in sort_priority if field not in data.columns]
        if missing_columns:
            raise ValueError(f"以下字段在数据中不存在: {missing_columns}")

        # 对每个排序字段进行自定义排序
        for field in sort_priority:
            if field in sort_orders:
                # 使用 pd.Categorical 定义自定义顺序
                data[field] = pd.Categorical(data[field], categories=sort_orders[field], ordered=True)

        # 按优先级进行排序
        sorted_data = data.sort_values(by=sort_priority).reset_index(drop=True)

        try:
            # 写回 Excel 文件
            with pd.ExcelWriter(filename, mode='a', if_sheet_exists='replace') as writer:
                sorted_data.to_excel(writer, sheet_name=sheet_name, index=False)
        except Exception as e:
            raise ValueError(f"写入 Excel 文件失败: {e}")

        print(f"文件已成功排序并保存: {filename}")

    @staticmethod
    def panel_to_long(data, id_vars: list, value_vars: list, var_name: str, value_name: str) -> pd.DataFrame:
        melted_data = pd.melt(
            data,
            id_vars=id_vars, 
            value_vars=value_vars,
            var_name=var_name,
            value_name=value_name
        )
        return melted_data

    @staticmethod
    def clean_empty_data(data: list) -> list:
        """
        清理列表中的空值(nan)数据
        
        参数:
            data (list): 需要清理的列表数据
            
        返回:
            list: 清理后的列表，移除了所有nan值
        """
        # 过滤掉None和pd.nan值
        return [x for x in data if pd.notna(x) and x is not None]

    @staticmethod
    def copy_file(file_path: str, new_file_path: str) -> None:
        """
        复制文件到新路径
        
        参数:
            file_path (str): 原始文件路径
            new_file_path (str): 新文件路径
        """
        shutil.copy(file_path, new_file_path)
