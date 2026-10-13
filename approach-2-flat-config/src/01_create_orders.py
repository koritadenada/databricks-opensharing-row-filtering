# Databricks notebook source
# MAGIC %md
# MAGIC # Create the orders base table
# MAGIC
# MAGIC Writes 1,000 synthetic orders, 250 per region (`CA`, `NY`, `TX`, `WA`).
# MAGIC In a real project this table comes from your pipeline; it is never added
# MAGIC to a share directly. Recipients read it only through the filtered view.

# COMMAND ----------

import re

# Unity Catalog names are backtick-quoted below, so most characters are fine.
# Reject only characters that would break the quoting or the name structure.
NAME = re.compile(r"^[^\s`'\"./\\]+$")


def param(name: str) -> str:
    value = dbutils.widgets.get(name)
    if not NAME.match(value):
        raise ValueError(f"Job parameter {name}={value!r} is not a valid Unity Catalog name")
    return value


catalog = param("catalog")
core_schema = param("core_schema")
orders_table = param("orders_table")

orders = f"`{catalog}`.`{core_schema}`.`{orders_table}`"

# COMMAND ----------

# One CREATE OR REPLACE ... AS SELECT is a single Delta commit, so readers of
# the shared view see either the old rows or the new rows, never an empty table.
spark.sql(
    f"""
    CREATE OR REPLACE TABLE {orders}
    COMMENT 'Synthetic orders. Shared only through the recipient-filtered view.'
    AS SELECT
      CAST(id AS BIGINT)                                                   AS order_id,
      date_add(DATE'2026-01-01', CAST(id % 180 AS INT))                    AS order_date,
      element_at(array('CA', 'NY', 'TX', 'WA'), CAST(id % 4 AS INT) + 1)   AS region,
      CAST(1000 + id % 97 AS BIGINT)                                       AS customer_id,
      CAST(10 + (id * 37) % 990 AS DECIMAL(10,2))                          AS amount
    FROM range(1, 1001)
    """
)

column_comments = {
    "order_id": "Order identifier",
    "order_date": "Date the order was placed",
    "region": "Region code; matched against the recipient property",
    "customer_id": "Customer identifier",
    "amount": "Order value",
}
for column, comment in column_comments.items():
    spark.sql(f"ALTER TABLE {orders} ALTER COLUMN `{column}` COMMENT '{comment}'")

display(spark.sql(f"SELECT region, count(*) AS orders FROM {orders} GROUP BY region ORDER BY region"))
