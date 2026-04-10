"""
sync_external_tables.py — Detect and fix stale Athena external table schemas.

Compares S3 data file headers with Athena table DDL columns. When the upstream
data adds new columns, this script detects the mismatch and can auto-recreate
the table with the correct schema.

Usage:
    python sync_external_tables.py                  # Dry-run: show mismatches
    python sync_external_tables.py --fix             # Auto-fix mismatched tables
    python sync_external_tables.py --table alpha_student  # Check single table
    python sync_external_tables.py --fix --table alpha_student  # Fix single table

Requires: boto3, AWS credentials with Athena + S3 access
"""
import argparse
import boto3
import re
import time
import sys

DATABASE = "studient"
WORKGROUP = "primary"
RESULTS_LOCATION = "s3://prod-academics-studient-athena-results/sync/"
REGION = "us-east-1"

# Map of human-readable S3 headers to snake_case column names
HEADER_NORMALIZATIONS = {
    "full student id": "fullid",
    "campus id": "campusid",
    "student id": "id",
    "first name": "firstname",
    "preferred name": "preferredname",
    "last name": "lastname",
    "date of birth": "dateofbirth",
    "current level": "alphalevellong",
    "current grade level": "gradelevel",
    "student alpha email": "email",
    "student group": "group",
    "withdraw date": "withdrawdate",
    "student portfolio url": "portfoliourl",
    "full name": "fullname",
    "level": "alphalevelshort",
    "level value": "alphalevel",
    "advisor email": "advisoremail",
    "map accomodations": "map_accommodations",
    "admission status": "admissionstatus",
    "admission date": "admission_date",
    "external student id": "externalstudentid",
}


def normalize_header(h):
    """Convert S3 header name to Athena column name."""
    h_lower = h.strip().lower()
    if h_lower in HEADER_NORMALIZATIONS:
        return HEADER_NORMALIZATIONS[h_lower]
    # Default: lowercase, replace spaces with underscores
    return re.sub(r'\s+', '_', h_lower)


def run_athena_query(client, sql, wait=True):
    """Execute an Athena query and optionally wait for results."""
    resp = client.start_query_execution(
        QueryString=sql,
        WorkGroup=WORKGROUP,
        QueryExecutionContext={"Database": DATABASE},
        ResultConfiguration={"OutputLocation": RESULTS_LOCATION},
    )
    qid = resp["QueryExecutionId"]
    if not wait:
        return qid

    while True:
        status = client.get_query_execution(QueryExecutionId=qid)
        state = status["QueryExecution"]["Status"]["State"]
        if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
            if state == "FAILED":
                reason = status["QueryExecution"]["Status"].get("StateChangeReason", "")
                raise RuntimeError(f"Query failed: {reason}")
            return qid
        time.sleep(1)


def get_query_results(client, qid):
    """Fetch all result rows from a completed query."""
    rows = []
    paginator = client.get_paginator("get_query_results")
    for page in paginator.paginate(QueryExecutionId=qid):
        for row in page["ResultSet"]["Rows"]:
            rows.append([c.get("VarCharValue", "") for c in row["Data"]])
    return rows[1:]  # skip header


def get_table_ddl(athena, table_name):
    """Get SHOW CREATE TABLE output, extract columns and metadata."""
    qid = run_athena_query(athena, f"SHOW CREATE TABLE {DATABASE}.{table_name}")
    rows = get_query_results(athena, qid)
    ddl = "\n".join(r[0] for r in rows)
    return ddl


def parse_ddl_columns(ddl):
    """Extract column names from DDL string."""
    # Match `column_name` type patterns
    cols = re.findall(r'`(\w+)`\s+\w+', ddl)
    return cols


def parse_ddl_location(ddl):
    """Extract S3 LOCATION from DDL."""
    match = re.search(r"LOCATION\s+'(s3://[^']+)'", ddl, re.IGNORECASE)
    return match.group(1) if match else None


def parse_ddl_delimiter(ddl):
    """Extract field delimiter from DDL."""
    if "FIELDS TERMINATED BY" in ddl:
        match = re.search(r"FIELDS TERMINATED BY '(.)'", ddl)
        return match.group(1) if match else ","
    if "separatorChar" in ddl:
        match = re.search(r"'separatorChar'='(.)'", ddl)
        return match.group(1) if match else ","
    if "ParquetHiveSerDe" in ddl:
        return None  # Parquet — schema embedded in file
    return ","


def get_s3_header(s3, location, delimiter):
    """Read the first line of the S3 data file and parse column names."""
    if not location or not delimiter:
        return None  # Can't read Parquet headers this way

    # Parse bucket and prefix
    parts = location.replace("s3://", "").split("/", 1)
    bucket = parts[0]
    prefix = parts[1] if len(parts) > 1 else ""
    # Ensure prefix ends with / so we don't match sibling directories
    # (e.g., "student" should not match "student-issue-detection/")
    if prefix and not prefix.endswith("/"):
        prefix += "/"

    # List files in the location
    resp = s3.list_objects_v2(Bucket=bucket, Prefix=prefix, MaxKeys=5)
    contents = resp.get("Contents", [])
    if not contents:
        return None

    # Find a data file (skip directories)
    data_file = None
    for obj in contents:
        key = obj["Key"]
        if key.endswith("/"):
            continue
        if obj["Size"] > 0:
            data_file = key
            break

    if not data_file:
        return None

    # Read just the first 2KB (enough for header)
    try:
        resp = s3.get_object(Bucket=bucket, Key=data_file, Range="bytes=0-2048")
        first_bytes = resp["Body"].read().decode("utf-8", errors="replace")
        first_line = first_bytes.split("\n")[0].strip()
        raw_headers = first_line.split(delimiter)
        headers = [normalize_header(h) for h in raw_headers]
        return headers
    except Exception as e:
        print(f"  Warning: Could not read S3 header: {e}")
        return None


def check_table(athena, s3, table_name, fix=False):
    """Compare Athena DDL columns with S3 header columns."""
    print(f"\n{'='*60}")
    print(f"Table: {table_name}")
    print(f"{'='*60}")

    try:
        ddl = get_table_ddl(athena, table_name)
    except Exception as e:
        print(f"  ERROR: Could not get DDL: {e}")
        return False

    ddl_cols = parse_ddl_columns(ddl)
    location = parse_ddl_location(ddl)
    delimiter = parse_ddl_delimiter(ddl)

    print(f"  S3 Location: {location}")
    print(f"  Delimiter: {repr(delimiter)}")
    print(f"  DDL columns: {len(ddl_cols)}")

    if delimiter is None:
        print(f"  Skipping: Parquet format (schema embedded in file)")
        return True

    s3_headers = get_s3_header(s3, location, delimiter)
    if s3_headers is None:
        print(f"  Skipping: Could not read S3 header")
        return True

    print(f"  S3 columns: {len(s3_headers)}")

    # Compare
    if len(s3_headers) == len(ddl_cols):
        print(f"  Status: OK (column counts match)")
        return True

    if len(s3_headers) > len(ddl_cols):
        new_cols = s3_headers[len(ddl_cols):]
        print(f"  MISMATCH: S3 has {len(s3_headers) - len(ddl_cols)} extra column(s): {new_cols}")

        if fix:
            print(f"  Fixing: Recreating table with {len(s3_headers)} columns...")
            # Build new column definitions (all as string type for safety)
            col_defs = []
            for col in s3_headers:
                # Preserve original type for known columns
                col_type = "string"
                for line in ddl.split("\n"):
                    if f"`{col}`" in line:
                        type_match = re.search(rf'`{col}`\s+(\w+)', line)
                        if type_match:
                            col_type = type_match.group(1)
                        break
                col_defs.append(f"  `{col}` {col_type}")

            # Extract SerDe and other properties from original DDL
            serde_section = ddl[ddl.find("ROW FORMAT"):]

            new_ddl = (
                f"CREATE EXTERNAL TABLE `{DATABASE}.{table_name}`(\n"
                + ",\n".join(col_defs)
                + ")\n"
                + serde_section
            )

            try:
                run_athena_query(athena, f"DROP TABLE IF EXISTS {DATABASE}.{table_name}")
                run_athena_query(athena, new_ddl)
                print(f"  Fixed! Table recreated with {len(s3_headers)} columns.")
                return True
            except Exception as e:
                print(f"  ERROR during fix: {e}")
                return False
        else:
            print(f"  Run with --fix to auto-recreate the table.")
            return False

    else:
        print(f"  WARNING: S3 has FEWER columns ({len(s3_headers)}) than DDL ({len(ddl_cols)})")
        print(f"  This may indicate the S3 data has been restructured.")
        return False


def main():
    parser = argparse.ArgumentParser(description="Sync Athena external table schemas with S3 data")
    parser.add_argument("--fix", action="store_true", help="Auto-fix mismatched tables")
    parser.add_argument("--table", type=str, help="Check a single table (default: all)")
    args = parser.parse_args()

    athena = boto3.client("athena", region_name=REGION)
    s3 = boto3.client("s3", region_name=REGION)

    if args.table:
        tables = [args.table]
    else:
        # Get all external tables (non-view objects)
        print("Fetching table list...")
        qid = run_athena_query(athena, f"SHOW TABLES IN {DATABASE}")
        all_tables = [r[0] for r in get_query_results(athena, qid)]
        # Filter to external tables (exclude views which start with khiem_)
        tables = [t for t in all_tables if not t.startswith("khiem_")]
        print(f"Found {len(tables)} external tables to check.")

    ok = 0
    mismatched = 0
    errors = 0

    for table in tables:
        result = check_table(athena, s3, table, fix=args.fix)
        if result:
            ok += 1
        else:
            mismatched += 1

    print(f"\n{'='*60}")
    print(f"Summary: {ok} OK, {mismatched} mismatched/errors out of {len(tables)} tables")
    if mismatched > 0 and not args.fix:
        print("Run with --fix to auto-recreate mismatched tables.")


if __name__ == "__main__":
    main()
