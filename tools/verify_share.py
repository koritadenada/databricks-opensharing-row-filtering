"""Read a share as an open sharing recipient and check the row filter.

Run this with a recipient's credential file (the file downloaded from the
activation link). It lists what the recipient can see, reads the shared
table, and fails unless every row belongs to the expected region.

    python tools/verify_share.py partner_ca.share \
        --table opensharing_ex1_orders.sales.orders --expect-region CA
"""

import argparse
import sys

import delta_sharing


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("profile", help="Path to the recipient's credential file (*.share)")
    parser.add_argument("--table", required=True, help="<share>.<schema>.<table> as the recipient sees it")
    parser.add_argument("--expect-region", required=True, help="Region the recipient should be limited to")
    parser.add_argument("--column", default="region", help="Column that holds the region (default: region)")
    args = parser.parse_args()

    client = delta_sharing.SharingClient(args.profile)
    visible = sorted(f"{t.share}.{t.schema}.{t.name}" for t in client.list_all_tables())
    print("Tables visible to this recipient:")
    for name in visible:
        print(f"  {name}")
    if args.table not in visible:
        print(f"FAIL: {args.table} is not visible to this recipient", file=sys.stderr)
        return 1

    df = delta_sharing.load_as_pandas(f"{args.profile}#{args.table}")
    counts = df[args.column].value_counts().sort_index()
    print(f"\nRows per {args.column}:")
    print(counts.to_string())

    unexpected = sorted(set(counts.index) - {args.expect_region})
    if df.empty or unexpected:
        print(f"\nFAIL: expected only {args.column}={args.expect_region}, got {list(counts.index)}", file=sys.stderr)
        return 1

    print(f"\nPASS: {len(df)} rows, all with {args.column}={args.expect_region}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
