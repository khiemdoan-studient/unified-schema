# AI Context Recovery Instructions — Unified Schema

**Purpose**: If Claude runs out of context, read this file first to understand the complete Athena data model.

## Project Overview

This repository documents the **Studient Athena data schema** — 28 virtual views and 21 external tables in the `studient` database on AWS Athena (account: `prod-academics-studient`, 882112397037). The schema is built on Presto/Trino SQL.

Three primary output views drive all downstream analytics:
1. **`khiem_v_lesson_unified`** — The massive unified view (foundation for everything)
2. **`khiem_v_weekly_dashboard`** — Weekly student aggregation (powers Google Sheets dashboard)
3. **`khiem_v_doom_loop_students`** — Intervention tracking for students stuck in test loops

## AWS Environment

| Property | Value |
|----------|-------|
| Account | prod-academics-studient (882112397037) |
| Region | us-east-1 |
| Service | AWS Athena (Presto/Trino SQL) |
| Database | `studient` |
| Catalog | `AwsDataCatalog` |
| IAM User | `vdi2tool.user` |
| Workgroup | `primary` |
| Query Results | `s3://studient-flat-exports/athena-results/` |

## File Map

| Path | Contents |
|------|----------|
| `ddl/views/*.sql` | 28 view DDL definitions |
| `ddl/tables/*.sql` | 21 external table DDL definitions |
| `diagrams/erd.mmd` | Mermaid ERD with all entities and relationships |
| `diagrams/dependency_tree.md` | ASCII dependency trees for the 3 primary views |
| `docs/AI_INSTRUCTIONS.md` | This file — AI context recovery |
| `docs/HUMAN_INSTRUCTIONS.md` | How to use this schema |
| `docs/CHANGELOG.md` | Version history |
| `docs/SCHEMA_REFERENCE.md` | Complete column-level reference for all views |

---

## The Three Primary Views

### 1. `khiem_v_lesson_unified` — The Foundation

**Purpose**: Combines Lessons, unmatched Activity, Tests, and Bracketing Assignments into one row-per-event table. This is the single source of truth for all student activity.

**Record Types** (UNION ALL):
| row_type | Source | Description |
|----------|--------|-------------|
| `Lesson` | `level_mastery` + roster | App lesson records (IXL, Edulastic, etc.) |
| `Activity` | `khiem_v_daily_time` (unmatched) | Time tracked but no matching lesson |
| `Test` | `khiem_v_test_scores_final` | Edulastic/CoachBot test results |
| `Bracketing Assignment` | `bracketing_assignments` | Knowledge grade assignments |

**CTEs** (in order):
| CTE | Description |
|-----|-------------|
| `target_campuses` | Hardcoded list of 12 campus IDs |
| `ixl_grade_lookup` | Maps IXL plan_grade text → numeric grade |
| `lesson_base` | Raw lessons from `level_mastery`, date ≥ 2025-01-01 |
| `lesson_with_roster` | Joins lessons → roster → alpha_student, filters to target campuses |
| `lesson_final` | Deduplicates lesson_with_roster (roster_dedup = 1) |
| `ixl_course_grade_parsed` | Parses IXL course names to extract numeric grade |
| `activity_unmatched` | Activity with NO matching lesson (LEFT JOIN → IS NULL) |
| `targets_map` | Daily mastery targets |
| `nwea_clean` | NWEA/MAP scores (fall/winter/spring RIT, CGP) |
| `cumulative_agg` | Running essential skill mastery counts |
| `taken_tests` | Edulastic test dates (for bracketing active check) |
| `all_records` | UNION ALL of 4 record types |

**Deduplication**: Final SELECT uses `ROW_NUMBER() OVER (PARTITION BY student_id, activity_date, row_type, app, subject, lesson_id, test_name, test_source, test_score)` keeping `dedupe_rn = 1`.

**Key Output Columns** (70+):
- **Identity**: `row_type`, `is_test`, `activity_date`, `student_id`, `student_name`, `campus_id`, `campus_name`, `school_name`, `student_group`, `grade`, `level`, `teacher_name`, `teacher_email`, `advisor_email`
- **Subject/App**: `subject_display`, `subject`, `app`, `course`
- **Activity Metrics**: `minutes_raw`, `minutes_working`, `units_mastered`, `correct_questions`, `total_questions`, `accuracy`
- **Mastery**: `levels_mastered`, `essential_units_attempted`, `essential_units_mastered`, `daily_mastery_target`, `mastery_vs_daily_target_pct`, `variance_vs_daily_target`, `target_status`
- **Lesson Details**: `lesson_name`, `topic`, `mastery_percentage`, `lesson_status`, `resource_type`, `lesson_url`, `lesson_id`
- **Test Details**: `test_source`, `test_name`, `test_type`, `test_score`, `test_max_score`, `test_accuracy`, `test_result`
- **NWEA/MAP**: `fall_rit`, `winter_rit`, `spring_rit`, `fall_cgp`, `winter_cgp`, `spring_cgp`, `f2w_projected_growth`, `f2w_observed_growth`, `map_growth_score`
- **Essential Skills**: `essential_levels_mastered_eng`, `total_mastered_essential_levels_eng`, `avg_essential_lessons_hardcoded`, `avg_essential_lessons_quicksight`, `grade_completion_target_day_quicksight`, `total_course_essential_levels_eng`, `grade_completion_target_day`
- **Bracketing/Onboarding**: `onboarding_status`, `knowledge_grade`, `test_group_key`, `knowledge_grade_label`, `grade_source`, `days_since_assignment`, `is_active_assignment`, `notes`
- **Other**: `lesson_rn`, `x_growth`, `antipatterns`, `antipattern_count`, `learning_level`, `learning_unit_passed`

**Unique Key**: `(student_id, activity_date, row_type, app, subject, lesson_id, test_name, test_source, test_score, dedupe_rn=1)`

---

### 2. `khiem_v_weekly_dashboard` — Weekly Aggregation

**Purpose**: One row per student per week. Cross-joins roster × weeks, left-joins weekly activity. Powers the Google Sheets dashboard via BigQuery.

**CTEs**:
| CTE | Description |
|-----|-------------|
| `sc_roster` | Distinct students with campus abbreviation mapping and school level |
| `weeks` | Distinct weeks from `khiem_v_lesson_unified` (DATE_TRUNC week), date ≥ 2025-08-01 |
| `weekly_activity` | Aggregated per student per week: minutes, days, tests, lessons, essential lessons |

**Join Pattern**: `sc_roster CROSS JOIN weeks LEFT JOIN weekly_activity` — ensures every student has a row for every week (even with 0 activity).

**Unique Key**: `(week_start, student_id)`

**Key Output Columns**:
| Column | Type | Description |
|--------|------|-------------|
| `week_start` | DATE | Monday of the week |
| `week_label` | VARCHAR | "Week of MM-DD-YY" |
| `student_id` | VARCHAR | Full student ID |
| `student_name` | VARCHAR | Student name |
| `campus_id` | VARCHAR | Campus ID |
| `school_abbrev` | VARCHAR | Short name (JHES, JRES, etc.) |
| `school_level` | VARCHAR | Elementary / Middle / High |
| `logged_in` | INTEGER | 1 if had any activity |
| `total_minutes` | DOUBLE | Total minutes worked |
| `days_active` | INTEGER | Distinct active days |
| `tests_taken` | INTEGER | Tests taken (excl. NWEA/MAP) |
| `tests_mastered` | INTEGER | Tests passed |
| `lessons_mastered` | INTEGER | Levels mastered |
| `essential_lessons_mastered` | INTEGER | Essential lessons mastered |
| `onboarding_status` | VARCHAR | ROSTERED / BRACKETING / ONBOARDED |

---

### 3. `khiem_v_doom_loop_students` — Intervention Tracking

**Purpose**: Identifies students with 3+ consecutive failures on the same subject/grade in Edulastic tests.

**CTEs**:
| CTE | Description |
|-----|-------------|
| `test_events` | Edulastic pass/fail results from `khiem_v_lesson_unified`, date ≥ 2025-01-01 |
| `running_counts` | Cumulative fail count per student/subject/knowledge_grade (window function) |
| `doom_loop_windows` | doom_loop_entry_date (when fails ≥ 3) and exit_date (first pass after entry) |

**Classification**:
- **Entered Doom Loop**: cumulative_fail_count ≥ 3
- **At Risk**: cumulative_fail_count = 2
- **Monitoring**: All others with test activity

**Unique Key**: `(student_id, subject, knowledge_grade)`

---

## Complete Dependency Map

### Direct Dependencies of `khiem_v_lesson_unified`

| Dependency | Type | Role |
|------------|------|------|
| `level_mastery` | EXTERNAL TABLE | Core lesson records |
| `khiem_v_roster` | VIEW → `alpha_student` | Student roster enrichment |
| `alpha_student` | EXTERNAL TABLE | Advisor emails, groups |
| `khiem_v_daily_time` | VIEW → `daily_learning_metrics` | Unmatched activity records |
| `khiem_v_essential_skill_counts` | VIEW → `skill_plan` | IXL grade lookup |
| `khiem_v_bracketing_history_ranges` | VIEW → `bracketing_assignments` | Knowledge grade ranges |
| `khiem_v_course_essential_totals` | VIEW → `khiem_v_full_skill_plan` → 3 tables | Essential counts per course |
| `khiem_v_daily_targets` | VIEW → `khiem_v_daily_time` + `khiem_v_roster` + `mastery_thresholds` | Daily targets |
| `khiem_v_nwea_comprehensive` | VIEW → `nwea_reports` | NWEA/MAP scores |
| `khiem_v_student_essential_mastery_from_lm` | VIEW → `level_mastery` + `daily_learning_metrics` + `khiem_v_roster` | Cumulative mastery |
| `khiem_v_test_scores_final` | VIEW → `edulastic_data` + `test_scores` + `khiem_v_nwea_comprehensive` + `khiem_identity_bridge` | Unified test scores |
| `edulastic_test_inventory` | EXTERNAL TABLE | Test metadata |

### Full Dependency Tree

See `diagrams/dependency_tree.md` for the complete tree.

### External Tables (Data Sources)

| Table | S3 Format | Key Columns | Purpose |
|-------|-----------|-------------|---------|
| `level_mastery` | Parquet | id, date, external_student_id, app, subject | Core lesson mastery records |
| `alpha_student` | Delimited | fullid, campusid, fullname, group | Student roster from SIS |
| `daily_learning_metrics` | Delimited | date, campus_id, external_student_id, subject, app | Daily time tracking |
| `bracketing_assignments` | CSV | full_student_id, subject, grade, onboarding_status | Knowledge grade assignments |
| `nwea_reports` | Delimited | studentid, subject, termname, testritscore | NWEA/MAP assessment scores |
| `edulastic_data` | Delimited | assignmentid, userid, title, score, maxscore | Edulastic test results |
| `test_scores` | Delimited | id, test_date, external_student_id, test_name, score | CoachBot test results |
| `skill_plan` | Delimited | skill_id, skill_code, app, subject, type, plan_grade | Curriculum skill definitions |
| `all_skills_ixl` | Delimited | skill_id, permacode, app, subject, grade | IXL skill catalog |
| `supporting_skills_map` | Delimited | essential_skill_id, supporting_skill_id | Essential→supporting mappings |
| `mastery_thresholds` | Delimited | campus_id, app, subject, grade, target_mastery_units | Daily mastery targets by campus |
| `edulastic_mastered_skills` | Delimited | external_student_id, date, subject, thirdpartylevelcode | Edulastic skill mastery |
| `edulastic_test_inventory` | Delimited | id, title, grade, subject | Test catalog |

---

## Intermediate View Reference

### `khiem_v_roster`
- **Source**: `alpha_student`
- **Purpose**: Deduplicated student roster with campus and teacher info, filtered to enrolled students only
- **Key**: `full_student_id` (guaranteed unique after dedup)
- **Logic**: Two-step filter: (1) `unenrolled` CTE excludes any fullid that has a "Former Student" or "Mid-Year Unenrollment" row — this prevents ghost students whose most-recent status is unenrolled but have older Enrolled rows (24 students); (2) `ROW_NUMBER() OVER (PARTITION BY fullid ORDER BY group-populated DESC)` deduplicates remaining Enrolled rows, keeping `rn = 1`. The `group` column is the primary tiebreaker — rows with group populated are always the current roster entry (144/149 confirmed, 0 false positives). Pre-dedup, `alpha_student` has 755 duplicate fullid rows among 5,055 enrolled students.

### `khiem_v_daily_time`
- **Source**: `daily_learning_metrics`
- **Purpose**: Daily aggregated time and learning metrics per student/subject/app
- **Key**: `(date, full_student_id, subject, app)`

### `khiem_identity_bridge`
- **Source**: `daily_learning_metrics`, `alpha_student`
- **Purpose**: Identity resolution across multiple ID formats (UUID, email, external_id, roster)
- **Key**: `(fullid, bridge_type)`

### `khiem_v_test_scores_final`
- **Source**: `edulastic_data`, `test_scores`, `khiem_v_nwea_comprehensive`, `khiem_identity_bridge`, `alpha_student`
- **Purpose**: Unified test scores from 3 sources with identity resolution
- **Key**: `(student_id, date, test_name, source_system)`

### `khiem_v_nwea_comprehensive`
- **Source**: `nwea_reports`
- **Purpose**: NWEA/MAP scores pivoted by term (fall/winter/spring)
- **Key**: `(full_student_id, subject_lower)`

### `khiem_v_bracketing_history_ranges`
- **Source**: `bracketing_assignments`
- **Purpose**: Temporal knowledge grade ranges for time-series joins
- **Key**: `(full_student_id, subject, valid_from_date)`

### `khiem_v_essential_skill_counts`
- **Source**: `skill_plan`
- **Purpose**: Total essential skills per app/subject/grade
- **Key**: `(app, subject, plan_grade)`

### `khiem_v_full_skill_plan`
- **Source**: `skill_plan`, `supporting_skills_map`, `all_skills_ixl`
- **Purpose**: Complete skill plan with essential + supporting skills
- **Key**: `(app, subject, skill_id, plan_grade)`

### `khiem_v_course_essential_totals`
- **Source**: `khiem_v_full_skill_plan`
- **Purpose**: Essential level count per course
- **Key**: `(app, subject, course)`

### `khiem_v_daily_targets`
- **Source**: `khiem_v_daily_time`, `khiem_v_roster`, `mastery_thresholds`
- **Purpose**: Daily mastery targets per student based on grade and app
- **Key**: `(date, full_student_id, subject, app)`

### `khiem_v_student_essential_mastery_from_lm`
- **Source**: `level_mastery`, `daily_learning_metrics`, `khiem_v_roster`
- **Purpose**: Daily essential skill mastery from learning apps
- **Key**: `(student_id, activity_date, subject, app)`

---

## Target Campuses (12 total)

| Campus ID | Abbreviation | Group | School Level |
|-----------|-------------|-------|--------------|
| 056 | JHES | Jasper | Elementary |
| 066 | JHMS | Jasper | Middle School |
| 033 | JRES | Jasper | Elementary |
| 068 | JRHS | Jasper | High School |
| 079 | Reading Community | Reading | K-12 |
| 082 | AFES | Allendale | Elementary |
| 083 | AFMS | Allendale | Middle School |
| 084 | AASP | Allendale | K-12 |
| 085 | Metro Schools | Metro | K-12 |
| 086 | ScienceSIS | — | — |
| 087 | Vita High School | — | High School |
| 088 | SPIRE Academy | — | — |

---

## Data Flow to Downstream Systems

```
Athena Views → S3 (Parquet export) → GCS → BigQuery → Google Sheets Dashboard
```

The `khiem_v_weekly_dashboard` view is exported and loaded into BigQuery table `studient_analytics.weekly_dashboard`, which powers the Student Performance Dashboard Google Sheet (`1ilTY0y-m6uZ0klw6Tq5tcKyS_jmwUFs3VzNZKyQGw1E`).

The `khiem_v_lesson_unified` view is exported and loaded into BigQuery table `studient_analytics.lesson_unified`, used for teacher/student analytics tabs.

See the [Studient Excel Automation](https://github.com/khiemdoan-studient/studient-excel-automation) repo for the ETL pipeline and dashboard builder.

---

## How to Modify Views

1. Open AWS Athena console: `https://us-east-1.console.aws.amazon.com/athena/home?region=us-east-1#/query-editor`
2. Select database: `studient`
3. Run `SHOW CREATE VIEW studient.<view_name>` to get current DDL
4. Modify and run `CREATE OR REPLACE VIEW studient.<view_name> AS ...`
5. Update the corresponding `.sql` file in `ddl/views/`
6. Update this documentation if columns or dependencies changed
7. Re-run the ETL pipeline (`Refresh-Data.ps1`) to propagate changes

## Common Gotchas

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| New students missing | Not in `alpha_student` table | Wait for SIS sync to S3 |
| Duplicate rows in dashboard | `alpha_student` has multiple rows per fullid | Already handled by `khiem_v_roster` dedup (v1.1.0) |
| Withdrawn student in data | Student not filtered by admission status | `khiem_v_roster` now filters to Enrolled only (v1.1.0) |
| Campus not appearing | Campus ID not in `target_campuses` CTE | Add to hardcoded list in `khiem_v_lesson_unified` |
| Test scores missing | Identity bridge can't resolve student | Check `khiem_identity_bridge` for the student UUID |
| Knowledge grade wrong | Stale `bracketing_assignments` data | Check `valid_from_date` / `valid_to_date` ranges |
| Weekly dashboard shows 0s | Student has no `khiem_v_lesson_unified` rows | Check if student has `level_mastery` records |
| NWEA scores null | Student not in `nwea_reports` | Wait for MAP data load |
| Target % is 0% everywhere | `essential_units_mastered` is mostly 0 | Dashboard uses `lessons_mastered` (all completed skills), not essentials. The `mastery_thresholds` targets measure all skills at 100 SmartScore, not just essential-tagged ones |
| Daily target is NULL | Student's app/subject/grade has no `mastery_thresholds` entry | Check `mastery_thresholds` table for the combination |

## Context Management

- Compact after finishing research/exploration, before starting implementation
- Compact after completing a major task before starting the next
- Compact after debugging before continuing feature work
- For subagents: use Sonnet (default) for file search and exploration. Escalate to Opus (`model: "opus"`) for complex SQL analysis, multi-view dependency tracing, or architectural decisions
