# AWS Credentials — Claude Automation

## IAM User: `claude-automation`

Created 2026-04-10 for programmatic access to the Prod-Academics-Studient account.

| Property | Value |
|----------|-------|
| Account | prod-academics-studient (882112397037) |
| IAM User | `claude-automation` |
| Access Key ID | `AKIA42YP673WT4MH6KWS` |
| Permissions | AdministratorAccess |
| Region | us-east-1 |

## Secret Access Key

**Do NOT commit the secret access key to git.**

Store it in one of these locations:
- `~/.aws/credentials` (via `aws configure`)
- Environment variables: `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`
- A secrets manager

## Usage

```bash
# Configure AWS CLI
aws configure
# Enter: AKIA42YP673WT4MH6KWS
# Enter: (secret key)
# Region: us-east-1
# Output: json

# Verify
aws sts get-caller-identity

# Run Athena query
aws athena start-query-execution \
  --query-string "SELECT * FROM studient.alpha_student LIMIT 5" \
  --work-group "primary" \
  --query-execution-context Database=studient \
  --result-configuration OutputLocation=s3://prod-academics-studient-athena-results/
```

## Athena Query Results Location

- **Primary**: `s3://prod-academics-studient-athena-results/`
- **Migration results**: `s3://prod-academics-studient-athena-results/migration/`

## Related Accounts

| Account | ID | Alias | Purpose |
|---------|-----|-------|---------|
| Prod-Academics-Studient | 882112397037 | prod-academics-studient | Production views, tables, ETL |
| RAPIDAPI | 515451715086 | rapidapi-aws | Upstream data feed (dash-data database) |

The RAPIDAPI account has a more up-to-date `dash-data.alpha_student` table with additional columns (`is_test`, `admission_date`, `externalstudentid`). As of 2026-04-10, the Prod account's `alpha_student` has been updated to match.
