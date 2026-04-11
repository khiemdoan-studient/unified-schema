# Human Instructions — Studient Unified Schema

## What This Repository Contains

This repository documents every Athena view and external table in the `studient` database that feeds into the three primary analytics views:

- **`khiem_v_lesson_unified`** — The core unified view combining lessons, activity, tests, and bracketing assignments
- **`khiem_v_weekly_dashboard`** — Weekly student metrics (powers the Google Sheets dashboard)
- **`khiem_v_doom_loop_students`** — Students stuck in repeated test failure loops

## Quick Start

### View a DDL
Browse `ddl/views/` for view definitions or `ddl/tables/` for external table definitions.

### Understand Dependencies
Open `diagrams/dependency_tree.md` to see how views feed into each other, or `diagrams/erd.mmd` for the full entity relationship diagram.

### Render the ERD
The ERD is in Mermaid format. To view it:
- **GitHub**: The `.mmd` file renders automatically in GitHub's web UI
- **VS Code**: Install the "Mermaid Preview" extension
- **Online**: Paste contents into [mermaid.live](https://mermaid.live)

---

## How to Query These Views

### Prerequisites
- AWS CLI configured with `prod-academics-studient` account (882112397037)
- Access to AWS Athena in `us-east-1`

### Using the Athena Console
1. Go to: https://us-east-1.console.aws.amazon.com/athena/home?region=us-east-1#/query-editor
2. Select database: `studient`
3. Run queries against any view or table

### Example Queries

**Get this week's student activity:**
```sql
SELECT student_name, campus_name, subject, app,
       SUM(minutes_working) AS total_minutes,
       SUM(levels_mastered) AS total_levels
FROM studient.khiem_v_lesson_unified
WHERE activity_date >= DATE_TRUNC('week', CURRENT_DATE)
  AND row_type = 'Lesson'
GROUP BY 1, 2, 3, 4
ORDER BY total_minutes DESC
LIMIT 50;
```

**Check weekly dashboard for a campus:**
```sql
SELECT week_label, COUNT(DISTINCT student_id) AS students,
       AVG(days_active) AS avg_days,
       AVG(total_minutes) AS avg_minutes
FROM studient.khiem_v_weekly_dashboard
WHERE school_abbrev = 'JHES'
  AND logged_in = 1
GROUP BY 1
ORDER BY 1 DESC
LIMIT 10;
```

**Find students in doom loops:**
```sql
SELECT student_name, campus_name, subject, knowledge_grade,
       total_fail_count, doom_loop_entry_date, doom_loop_exit_date,
       overall_status
FROM studient.khiem_v_doom_loop_students
WHERE overall_status = 'Entered Doom Loop'
  AND has_exited = false
ORDER BY total_fail_count DESC;
```

**Get a view's DDL:**
```sql
SHOW CREATE VIEW studient.khiem_v_lesson_unified;
```

---

## Schema Overview

### View Categories

| Category | Views | Purpose |
|----------|-------|---------|
| **Primary Outputs** | `khiem_v_lesson_unified`, `khiem_v_weekly_dashboard`, `khiem_v_doom_loop_students` | Main analytics views |
| **Student Identity** | `khiem_v_roster`, `khiem_identity_bridge` | Student dedup & enrichment (roster filters to Enrolled only) |
| **Activity/Time** | `khiem_v_daily_time`, `khiem_v_lesson_activity`, `khiem_v_lesson_activity_full`, `khiem_v_lesson_detail`, `khiem_v_student_lessons` | Learning activity records |
| **Tests** | `khiem_v_test_scores_final` | Unified test scores (3 sources) |
| **Assessments** | `khiem_v_nwea_comprehensive` | NWEA/MAP scores |
| **Bracketing** | `khiem_v_bracketing_history_ranges` | Knowledge grade tracking |
| **Essential Skills** | `khiem_v_essential_skill_counts`, `khiem_v_essential_skills`, `khiem_v_full_skill_plan`, `khiem_v_course_essential_totals`, `khiem_v_essential_units`, `khiem_v_essential_units_daily`, `khiem_v_daily_essential_mastery`, `khiem_v_student_essential_mastery_from_lm`, `khiem_v_student_ixl_essential_mastery`, `khiem_v_student_edulastic_essential_mastery`, `khiem_v_student_essential_progress`, `khiem_v_student_progress_metrics` | Skill mastery tracking |
| **Targets** | `khiem_v_daily_targets` | Daily mastery targets |
| **Security** | `khiem_v_rls_teacher_students` | Row-Level Security for QuickSight |
| **Legacy** | `khiem_v_student_activity_flat` | Older unified view (pre-lesson_unified) |

### External Tables (Data Sources)

| Table | Format | Source System |
|-------|--------|---------------|
| `level_mastery` | Parquet | Alpha/LearningApp |
| `alpha_student` | Delimited | Alpha SIS |
| `daily_learning_metrics` | Delimited | Alpha/LearningApp |
| `bracketing_assignments` | CSV | Bracketing system |
| `nwea_reports` | Delimited | NWEA/MAP |
| `edulastic_data` | Delimited | Edulastic |
| `edulastic_mastered_skills` | Delimited | Edulastic |
| `edulastic_test_inventory` | Delimited | Edulastic |
| `test_scores` | Delimited | CoachBot |
| `skill_plan` | Delimited | Curriculum team |
| `all_skills_ixl` | Delimited | IXL |
| `supporting_skills_map` | Delimited | Curriculum team |
| `mastery_thresholds` | Delimited | Admin config |
| `student_app_roster` | Delimited | App enrollment |

---

## How to Modify a View

1. Get the current DDL:
   ```sql
   SHOW CREATE VIEW studient.<view_name>;
   ```

2. Make your changes and run:
   ```sql
   CREATE OR REPLACE VIEW studient.<view_name> AS
   -- your updated SQL here
   ```

3. Update the corresponding file in `ddl/views/<view_name>.sql`

4. If you changed columns or dependencies, update:
   - `docs/AI_INSTRUCTIONS.md`
   - `diagrams/erd.mmd`
   - `diagrams/dependency_tree.md`

5. If the change affects downstream ETL, re-run the pipeline:
   ```powershell
   cd "C:\Users\doank\Documents\Projects\Studient Excel Automation"
   .\Refresh-Data.ps1
   ```

## How to Add a New Campus

1. Add the campus_id to the `target_campuses` CTE in `khiem_v_lesson_unified`
2. Add the campus abbreviation mapping in `khiem_v_weekly_dashboard`'s `sc_roster` CTE
3. Run `CREATE OR REPLACE VIEW` for both views
4. Update the `SCHOOL_GROUPS` dict in the Excel Automation project if needed

## How to Add a New External Table

1. Create the table in Athena pointing to the S3 location:
   ```sql
   CREATE EXTERNAL TABLE studient.new_table (
     col1 STRING,
     col2 INT
   )
   ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
   LOCATION 's3://your-bucket/path/'
   TBLPROPERTIES ('skip.header.line.count'='1');
   ```

2. Save the DDL to `ddl/tables/new_table.sql`
3. Update documentation if it's used by any views

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| View returns 0 rows | Check if source tables have data: `SELECT COUNT(*) FROM studient.<source_table>` |
| "Table not found" | Check you're in the `studient` database and the table exists in Glue catalog |
| Slow query | `khiem_v_lesson_unified` is large — add `WHERE activity_date >= ...` filters |
| Identity mismatch | Check `khiem_identity_bridge` for the student's ID resolution |
| S3 data stale | Data is synced from source systems on a schedule — check S3 timestamps |

## Related Projects

| Project | Purpose |
|---------|---------|
| [Studient Excel Automation](https://github.com/khiemdoan-studient/studient-excel-automation) | ETL pipeline: Athena → S3 → GCS → BigQuery → Google Sheets |
| [Email Automation](https://github.com/khiemdoan-studient/email-automation) | Google Apps Script for teacher weekly report emails |
