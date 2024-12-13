from lib import *
from const import Constant
class Workflow:
    def __init__(self, file_name, sheet_name, constraint_vars: dict, is_long_format=True, long_format_params=None, is_missing_data=False, y_columns: list[str] = []):
        self.file_name = file_name
        self.sheet_name = sheet_name
        self.constraint_vars = constraint_vars

        if not is_long_format:
            self.data_cleaner = DataCleaner(
                file_path=self.file_name,
                sheet_name=self.sheet_name,
                is_long_format=is_long_format,
                long_format_params=long_format_params
            )
        else:
            self.data_cleaner = DataCleaner(
                file_path=self.file_name,
                sheet_name=self.sheet_name,
            )

        self.data_cleaner.replace_column_name(Constant.CITIES_NAME, 'city')
        self.data_cleaner.replace_column_name(Constant.YEARS_NAME, 'year')

        self.data_cleaner.clean_column_data('city', '市')

        for key, value in self.constraint_vars.items():
            self.data_cleaner.clean_data_keep_values(key, value)
        
        self.data_cleaner.rearrange_data(
            sort_priority=self.constraint_vars.keys(),
            sort_orders=self.constraint_vars
        )

        if is_missing_data:
            self.process_missing_data(y_columns, 'city', 'year')
    
    def close_and_save(self):
        self.data_cleaner.close_file_and_save()

