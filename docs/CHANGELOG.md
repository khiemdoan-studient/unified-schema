# Changelog — Unified Schema

All notable changes to the Studient Athena schema documentation.

## [v1.1.2] — 2026-04-08

### Fixed
- **`khiem_v_roster` — Ghost student exclusion** — 24 students whose most-recent status was "Former Student" (21 at JRHS) or "Mid-Year Unenrollment" (3 others) were incorrectly appearing in the roster because older "Enrolled" rows passed the v1.1.0 filter. Fix: new `unenrolled` CTE excludes any `fullid` that has a "Former Student" or "Mid-Year Unenrollment" row before dedup runs. Verified: 0 re-enrolled students exist in the data, so this exclusion is safe.

## [v1.1.1] — 2026-04-07

### Fixed
- **`khiem_v_lesson_unified` — alpha_student dedup** — All 4 `LEFT JOIN studient.alpha_student ast` replaced with `LEFT JOIN alpha_student_dedup ast` (new CTE with same ROW_NUMBER dedup logic as roster). Eliminates row multiplication in Lesson, Activity, Test, and Bracketing Assignment branches. Column `ast."group"` aliased to `ast.student_group` to avoid SQL reserved word issues in Athena.
- **`khiem_v_weekly_dashboard` — alpha_student dedup** — Same `alpha_student_dedup` CTE added. The `sc_roster` CTE's `LEFT JOIN alpha_student` replaced with deduped version. Fixes WPD Student Breakdown showing double rows per student (one with group, one without).
- **Impact**: `_Data` sheet reduced from 71,360 to 66,592 rows (4,768 duplicate student-week entries eliminated across all campuses).

## [v1.1.0] — 2026-04-06

### Changed
- **`khiem_v_roster` — Dedup + Enrolled filter** — The view now deduplicates `alpha_student` rows using `ROW_NUMBER() OVER (PARTITION BY fullid)` with the `group` column as the primary tiebreaker, and filters to `admissionstatus = 'Enrolled'` only. Previously, the view was a plain `SELECT` from `alpha_student` with no dedup or status filter, producing 755 duplicate rows out of 5,055 enrolled students. This caused row multiplication in downstream `CROSS JOIN` views like `khiem_v_weekly_dashboard`.

### Analysis Summary
- 5,055 unique enrolled students in `alpha_student`
- 606 exact duplicates (identical advisor + group) — handled by any dedup
- 109 group-only changes — first row in file always has group populated (109/109)
- 34 advisor + group changes — first row has group (34/34)
- 6 advisor-only changes — 5 with no group on any row (fall to tiebreaker), 1 with consistent group
- 0 false positives (old row has group, current doesn't)

### Downstream Impact
| View | Impact |
|------|--------|
| `khiem_v_weekly_dashboard` | FIXED — eliminates duplicate rows from roster CROSS JOIN weeks |
| `khiem_v_lesson_unified` | FIXED — existing `roster_dedup` ROW_NUMBER becomes redundant (harmless) |
| `khiem_v_doom_loop_students` | FIXED — inherits clean data from lesson_unified |
| `khiem_v_daily_targets` | FIXED — 1:1 join on full_student_id |
| `khiem_v_student_essential_mastery_from_lm` | FIXED — manual roster dedup CTE becomes redundant |
| `khiem_v_lesson_detail` | FIXED — join on external_student_id now 1:1 |
| `khiem_v_student_activity_flat` | FIXED — join on full_student_id now 1:1 |
| `khiem_v_rls_teacher_students` | FIXED — DISTINCT becomes redundant |
| `khiem_v_lesson_activity_full` | FIXED — DISTINCT becomes redundant |
| `khiem_identity_bridge` | NOT AFFECTED — joins alpha_student directly (separate fix needed) |
| `khiem_v_test_scores_final` | NOT AFFECTED — joins alpha_student directly (separate fix needed) |

---

## [v1.0.0] — 2026-03-29

### Added
- **Initial schema extraction** — 28 virtual views and 21 external tables from AWS Athena `studient` database
- **DDL files** — individual SQL files for all views (`ddl/views/`) and external tables (`ddl/tables/`)
- **Entity Relationship Diagram** — Mermaid ERD (`diagrams/erd.mmd`) covering all entities, columns, types, and relationships
- **Dependency tree** — ASCII tree (`diagrams/dependency_tree.md`) showing how views feed into the 3 primary outputs
- **AI Instructions** — context recovery doc (`docs/AI_INSTRUCTIONS.md`) with complete view documentation, CTEs, column references, and dependency maps
- **Human Instructions** — usage guide (`docs/HUMAN_INSTRUCTIONS.md`) with example queries, modification procedures, and troubleshooting
- **Schema reference** — complete column-level documentation for all views (`docs/SCHEMA_REFERENCE.md`)
- **README** — project overview and quick start

### Views Documented (28)
| View | Category |
|------|----------|
| `khiem_v_lesson_unified` | Primary output — unified lesson/activity/test/bracketing |
| `khiem_v_weekly_dashboard` | Primary output — weekly student aggregation |
| `khiem_v_doom_loop_students` | Primary output — intervention tracking |
| `khiem_v_roster` | Identity — student roster |
| `khiem_identity_bridge` | Identity — cross-system resolution |
| `khiem_v_daily_time` | Activity — daily time tracking |
| `khiem_v_lesson_activity` | Activity — lesson extraction |
| `khiem_v_lesson_activity_full` | Activity — enriched lessons |
| `khiem_v_lesson_detail` | Activity — detailed lesson records |
| `khiem_v_student_lessons` | Activity — student lesson list |
| `khiem_v_test_scores_final` | Tests — unified test scores |
| `khiem_v_nwea_comprehensive` | Assessments — NWEA/MAP scores |
| `khiem_v_bracketing_history_ranges` | Bracketing — knowledge grade ranges |
| `khiem_v_essential_skill_counts` | Essential skills — counts by grade |
| `khiem_v_essential_skills` | Essential skills — skill definitions |
| `khiem_v_full_skill_plan` | Essential skills — complete plan |
| `khiem_v_course_essential_totals` | Essential skills — per-course totals |
| `khiem_v_essential_units` | Essential skills — daily units |
| `khiem_v_essential_units_daily` | Essential skills — daily aggregation |
| `khiem_v_daily_essential_mastery` | Essential skills — daily mastery |
| `khiem_v_student_essential_mastery_from_lm` | Essential skills — from level_mastery |
| `khiem_v_student_ixl_essential_mastery` | Essential skills — IXL mastery |
| `khiem_v_student_edulastic_essential_mastery` | Essential skills — Edulastic mastery |
| `khiem_v_student_essential_progress` | Essential skills — progress % |
| `khiem_v_student_progress_metrics` | Essential skills — growth metrics |
| `khiem_v_daily_targets` | Targets — daily mastery targets |
| `khiem_v_rls_teacher_students` | Security — teacher RLS mapping |
| `khiem_v_student_activity_flat` | Legacy — older unified view |

### External Tables Documented (21)
`level_mastery`, `alpha_student`, `daily_learning_metrics`, `bracketing_assignments`, `nwea_reports`, `edulastic_data`, `edulastic_mastered_skills`, `edulastic_test_inventory`, `test_scores`, `skill_plan`, `all_skills_ixl`, `supporting_skills_map`, `mastery_thresholds`, `student_app_roster`, `app_mapping_data`, `learning_app_time`, `app_chronicle`, `missing_minutes_override`, `recommendation`, `twohr_overrides`, `quicksight_rls_sc_teachers`
