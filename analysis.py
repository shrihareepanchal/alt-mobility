import pandas as pd
import sqlite3
import matplotlib.pyplot as plt
import seaborn as sns

# Load Data
orders_df = pd.read_csv('customer_orders.csv')
payments_df = pd.read_csv('payments.csv')

# Print the columns in orders_df to verify if total_amount exists
print("Columns in orders_df:", orders_df.columns)

# Create SQLite DB and load tables
conn = sqlite3.connect('alt_mobility.db')
orders_df.to_sql('customer_orders', conn, if_exists='replace', index=False)
payments_df.to_sql('payments', conn, if_exists='replace', index=False)

# Inspect the columns in the SQLite table
query_columns = """
PRAGMA table_info(customer_orders);
"""
columns_info = pd.read_sql(query_columns, conn)
print(columns_info)

# Function to execute SQL queries from file
def execute_sql_from_file(file_path):
    with open(file_path, 'r') as file:
        sql_queries = file.read().split(';')
    results = []
    for query in sql_queries:
        if query.strip():
            result = pd.read_sql(query, conn)
            results.append(result)
    return results

# Run all SQL queries from the file
queries_results = execute_sql_from_file('queries.sql')

# Output the results (you can also save them if needed)
for i, result in enumerate(queries_results):
    print(f"Result of Query {i+1}:\n", result)

# Convert order_date to datetime
orders_df['order_date'] = pd.to_datetime(orders_df['order_date'])

# Cohort Setup
orders_df['order_month'] = orders_df['order_date'].dt.to_period('M')
first_order = orders_df.groupby('customer_id')['order_month'].min()
orders_df['cohort_month'] = orders_df['customer_id'].map(first_order)

def get_month_diff(start, end):
    return (end.year - start.year) * 12 + (end.month - start.month)

orders_df['cohort_index'] = orders_df.apply(
    lambda row: get_month_diff(row['cohort_month'].to_timestamp(), row['order_month'].to_timestamp()), axis=1
)

cohort_data = orders_df.groupby(['cohort_month', 'cohort_index'])['customer_id'].nunique().unstack(fill_value=0)
retention = cohort_data.divide(cohort_data.iloc[:, 0], axis=0) * 100

# Plotting Retention Heatmap
plt.figure(figsize=(12, 6))
sns.heatmap(retention, annot=True, fmt=".0f", cmap="Blues")
plt.title("Customer Retention by Cohort")
plt.xlabel("Months Since First Order")
plt.ylabel("Cohort (First Order Month)")
plt.tight_layout()
plt.savefig("retention_heatmap.png")
plt.show()
