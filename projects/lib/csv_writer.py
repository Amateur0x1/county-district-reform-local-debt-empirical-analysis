import csv
from typing import List, Dict, Any

class CSVWriter:
    """
    CSV文件写入类，用于逐行写入CSV文件
    
    参数:
        output_file (str): 输出CSV文件路径
    """
    def __init__(self, output_file: str):
        self.output_file = output_file
        self.data = []
        self.columns = []
    
    def set_columns(self, columns: List[str]):
        """
        设置CSV文件的列名
        
        参数:
            columns (List[str]): 列名列表
        """
        self.columns = columns
    
    def add_row(self, row: Dict[str, Any]):
        """
        添加一行数据
        
        参数:
            row (Dict[str, Any]): 行数据字典，键为列名，值为对应的数据
        """
        self.data.append([row.get(col, '') for col in self.columns])
    
    def write(self):
        """
        将数据写入CSV文件
        """
        with open(self.output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(self.columns)
            writer.writerows(self.data)
