# Changelog — Unified Schema

All notable changes to the Studient Athena schema documentation.

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
