# Studient Unified Schema

Schema documentation, DDLs, and entity relationship diagrams for the Studient Athena data model.

## Overview

This repository documents the complete data schema for the `studient` database on AWS Athena (account: `prod-academics-studient`). It includes **28 virtual views** and **21 external tables** that power student performance analytics across 12 campuses.

### Three Primary Output Views

| View | Purpose | Unique Key |
|------|---------|------------|
| `khiem_v_lesson_unified` | Unified lessons, activity, tests, and bracketing — the foundation for all analytics | `(student_id, activity_date, row_type, app, subject, lesson_id)` |
| `khiem_v_weekly_dashboard` | Weekly student aggregation — powers the Google Sheets dashboard | `(week_start, student_id)` |
| `khiem_v_doom_loop_students` | Students with 3+ consecutive test failures — intervention tracking | `(student_id, subject, knowledge_grade)` |

### Data Flow

```
External Tables (S3)  →  Intermediate Views  →  Primary Views  →  S3 Export  →  GCS  →  BigQuery  →  Google Sheets
```

## Repository Structure

```
unified-schema/
├── README.md
├── ddl/
│   ├── views/          # 28 view DDL files
│   │   ├── khiem_v_lesson_unified.sql
│   │   ├── khiem_v_weekly_dashboard.sql
│   │   ├── khiem_v_doom_loop_students.sql
│   │   └── ... (25 more)
│   └── tables/         # 21 external table DDL files
│       ├── level_mastery.sql
│       ├── alpha_student.sql
│       └── ... (19 more)
├── diagrams/
│   ├── erd.mmd                 # Mermaid Entity Relationship Diagram
│   └── dependency_tree.md      # ASCII dependency trees
└── docs/
    ├── AI_INSTRUCTIONS.md      # AI context recovery (complete schema reference)
    ├── HUMAN_INSTRUCTIONS.md   # How to query and modify views
    ├── CHANGELOG.md            # Version history
    └── SCHEMA_REFERENCE.md     # Column-level reference for all views
```

## Quick Start

### View the ERD
The `diagrams/erd.mmd` file renders automatically on GitHub. Click it to see the full entity relationship diagram.

### Browse DDLs
Each view and table has its own `.sql` file in `ddl/views/` or `ddl/tables/`.

### Understand Dependencies
See `diagrams/dependency_tree.md` for how views chain together.

### Query in Athena
```sql
-- Example: This week's top students by minutes
SELECT student_name, campus_name, SUM(minutes_working) AS mins
FROM studient.khiem_v_lesson_unified
WHERE activity_date >= DATE_TRUNC('week', CURRENT_DATE)
GROUP BY 1, 2 ORDER BY mins DESC LIMIT 20;
```

## Environment

| Property | Value |
|----------|-------|
| AWS Account | prod-academics-studient (882112397037) |
| Region | us-east-1 |
| Database | `studient` |
| Engine | Athena (Presto/Trino SQL) |

## Related Projects

- [Studient Excel Automation](https://github.com/khiemdoan-studient/studient-excel-automation) — ETL + Google Sheets dashboard
- [Email Automation](https://github.com/khiemdoan-studient/email-automation) — Teacher weekly report emails
