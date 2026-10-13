# Databricks notebook source
# MAGIC %md
# MAGIC # Create the recipient-filtered view
# MAGIC
# MAGIC `current_recipient('<key>')` returns the value of a property on the
# MAGIC recipient that runs the query. Each recipient of the share sees only the
# MAGIC rows whose `region` equals its own `region` property.
# MAGIC
# MAGIC The function only evaluates in an OpenSharing context, so you, the
# MAGIC provider, cannot query this view directly. Test it as a recipient (see
# MAGIC `tools/verify_share.py`).

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
shared_schema = param("shared_schema")
orders_table = param("orders_table")
shared_view = param("shared_view")
recipient_property = param("recipient_property")

orders = f"`{catalog}`.`{core_schema}`.`{orders_table}`"
view = f"`{catalog}`.`{shared_schema}`.`{shared_view}`"

# COMMAND ----------

# List columns explicitly: a new column in the base table must not reach
# recipients until you add it here on purpose.
query = f"""
    SELECT order_id, order_date, region, customer_id, amount
    FROM {orders}
    WHERE region = current_recipient('{recipient_property}')
"""

# A view that is in a share cannot be dropped, and CREATE OR REPLACE VIEW
# drops it. Create the view on the first run; afterwards update it in place
# with ALTER VIEW so the share keeps pointing at the same object.
if spark.catalog.tableExists(view):
    spark.sql(f"ALTER VIEW {view} AS {query}")
else:
    spark.sql(f"CREATE VIEW {view} AS {query}")

# Set on every run so the comment follows changes to the recipient property.
spark.sql(
    f"COMMENT ON TABLE {view} IS "
    f"'Orders filtered to the region in the recipient property `{recipient_property}` of the querying recipient.'"
)

print(f"{view} now reads from {orders}")
