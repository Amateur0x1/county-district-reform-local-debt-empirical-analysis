import pandas as pd
from const import data_path

df = pd.read_excel(data_path)

print(df.head())