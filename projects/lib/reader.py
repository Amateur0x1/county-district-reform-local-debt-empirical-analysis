import pandas as pd

class ExcelReader:
    def __init__(self, file_path):
        self.file_path = file_path
        
    def read_column(self, sheet_name, column_name):
        """读取指定sheet中的指定列数据，返回列表"""
        df = pd.read_excel(self.file_path, sheet_name=sheet_name)
        if column_name in df.columns:
            return df[column_name].tolist()
        else:
            raise ValueError(f"Column '{column_name}' not found in sheet '{sheet_name}'")

    def read_column_by_index(self, sheet_name, column_index):
        """读取指定sheet中的指定列索引的数据，返回列表"""
        df = pd.read_excel(self.file_path, sheet_name=sheet_name)
        if column_index < len(df.columns):
            return df.iloc[:, column_index].tolist()
        else:
            raise ValueError(f"Column index '{column_index}' out of range for sheet '{sheet_name}'")
