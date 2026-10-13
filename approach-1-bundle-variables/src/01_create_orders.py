# Databricks notebook source
# MAGIC %md
# MAGIC # Create the orders base table
# MAGIC
# MAGIC Writes 1,000 synthetic orders, 250 per region (`CA`, `NY`, `TX`, `WA`).
# MAGIC In a real project this table comes from your pipeline; it is never added
# MAGIC to a share directly. Recipients read it only through the filtered view.

# COMMAND ----------

import re

IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def param(name: str) -> str:
    value = dbutils.widgets.get(name)
    if not IDENTIFIER.match(value):
        raise ValueError(f"Job parameter {name}={value!r} is not a valid identifier")
    return value


catalog = param("catalog")
core_schema = param("core_schema")
orders_table = param("orders_table")

orders = f"`{catalog}`.`{core_schema}`.`{orders_table}`"

# COMMAND ----------

spark.sql(
    f"""
    CREATE OR REPLACE TABLE {orders} (
      order_id    BIGINT        NOT NULL COMMENT 'Order identifier',
      order_date  DATE          NOT NULL COMMENT 'Date the order was placed',
      region      STRING        NOT NULL COMMENT 'Region code; matched against the recipient property',
      customer_id BIGINT        NOT NULL COMMENT 'Customer identifier',
      amount      DECIMAL(10,2) NOT NULL COMMENT 'Order value'
    )
    COMMENT 'Synthetic orders. Shared only through the recipient-filtered view.'
    """
)

spark.sql(
    f"""
    INSERT INTO {orders}
    SELECT
      id                                                  AS order_id,
      date_add(DATE'2026-01-01', CAST(id % 180 AS INT))   AS order_date,
      element_at(array('CA', 'NY', 'TX', 'WA'), CAST(id % 4 AS INT) + 1) AS region,
      1000 + id % 97                                      AS customer_id,
      CAST(10 + (id * 37) % 990 AS DECIMAL(10,2))         AS amount
    FROM range(1, 1001)
    """
)

display(spark.sql(f"SELECT region, count(*) AS orders FROM {orders} GROUP BY region ORDER BY region"))
