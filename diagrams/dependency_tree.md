# View Dependency Tree

This document shows how views and external tables flow into the three primary output views.

## Primary Output Views

### 1. `khiem_v_lesson_unified` — The Foundation

```
khiem_v_lesson_unified
├── level_mastery                          (EXTERNAL TABLE — core lesson records)
├── khiem_v_roster                         (VIEW)
│   └── alpha_student                      (EXTERNAL TABLE — SIS roster)
├── alpha_student                          (EXTERNAL TABLE — advisor emails, groups)
├── khiem_v_essential_skill_counts         (VIEW)
│   └── skill_plan                         (EXTERNAL TABLE — curriculum skills)
├── khiem_v_daily_time                     (VIEW)
│   └── daily_learning_metrics             (EXTERNAL TABLE — time tracking)
├── khiem_v_bracketing_history_ranges      (VIEW)
│   └── bracketing_assignments             (EXTERNAL TABLE — knowledge grades)
├── khiem_v_course_essential_totals        (VIEW)
│   └── khiem_v_full_skill_plan            (VIEW)
│       ├── skill_plan                     (EXTERNAL TABLE)
│       ├── supporting_skills_map          (EXTERNAL TABLE)
│       └── all_skills_ixl                 (EXTERNAL TABLE)
├── khiem_v_daily_targets                  (VIEW)
│   ├── khiem_v_daily_time                 (VIEW → daily_learning_metrics)
│   ├── khiem_v_roster                     (VIEW → alpha_student)
│   └── mastery_thresholds                 (EXTERNAL TABLE)
├── khiem_v_nwea_comprehensive             (VIEW)
│   └── nwea_reports                       (EXTERNAL TABLE — MAP scores)
├── khiem_v_student_essential_mastery_from_lm  (VIEW)
│   ├── level_mastery                      (EXTERNAL TABLE)
│   ├── daily_learning_metrics             (EXTERNAL TABLE)
│   └── khiem_v_roster                     (VIEW → alpha_student)
├── khiem_v_test_scores_final              (VIEW)
│   ├── edulastic_data                     (EXTERNAL TABLE)
│   ├── test_scores                        (EXTERNAL TABLE)
│   ├── khiem_v_nwea_comprehensive         (VIEW → nwea_reports)
│   ├── khiem_identity_bridge              (VIEW)
│   │   ├── daily_learning_metrics         (EXTERNAL TABLE)
│   │   └── alpha_student                  (EXTERNAL TABLE)
│   └── alpha_student                      (EXTERNAL TABLE)
└── edulastic_test_inventory               (EXTERNAL TABLE — test metadata)
```

### 2. `khiem_v_weekly_dashboard` — Weekly Aggregation

```
khiem_v_weekly_dashboard
├── khiem_v_roster                         (VIEW → alpha_student)
├── alpha_student                          (EXTERNAL TABLE)
└── khiem_v_lesson_unified                 (VIEW — see full tree above)
```

### 3. `khiem_v_doom_loop_students` — Intervention Tracking

```
khiem_v_doom_loop_students
└── khiem_v_lesson_unified                 (VIEW — see full tree above)
```

## Standalone / Leaf Views (no downstream dependents in the primary outputs)

These views exist for QuickSight dashboards, ad-hoc analysis, or other consumers:

| View | Purpose |
|------|---------|
| `khiem_v_lesson_activity` | Simple lesson extraction from level_mastery |
| `khiem_v_lesson_activity_full` | Lesson activity with roster enrichment |
| `khiem_v_lesson_detail` | Detailed lesson records with campus context |
| `khiem_v_rls_teacher_students` | Teacher→student mapping for Row-Level Security |
| `khiem_v_student_activity_flat` | Unified activity+test records (older version of lesson_unified) |
| `khiem_v_student_lessons` | All student lessons with completion status |
| `khiem_v_essential_skills` | Distinct essential skills by grade/subject |
| `khiem_v_essential_units` | Essential/total units completed per day |
| `khiem_v_essential_units_daily` | Daily aggregated essential units |
| `khiem_v_daily_essential_mastery` | Daily essential skill mastery counts |
| `khiem_v_student_essential_progress` | Student progress on essential skills with % |
| `khiem_v_student_progress_metrics` | Progress metrics with 2x growth targets |
| `khiem_v_student_ixl_essential_mastery` | IXL essential skill mastery records |
| `khiem_v_student_edulastic_essential_mastery` | Edulastic essential skill mastery records |

## Critical Hub Objects

| Object | Type | Dependents | Role |
|--------|------|------------|------|
| `alpha_student` | EXTERNAL TABLE | 12+ views | Foundation for all student context |
| `level_mastery` | EXTERNAL TABLE | 8+ views | Foundation for lesson/activity data |
| `daily_learning_metrics` | EXTERNAL TABLE | 5+ views | Foundation for time/activity metrics |
| `khiem_v_roster` | VIEW | 12+ views | Most-referenced view (student enrichment) |
| `khiem_v_lesson_unified` | VIEW | 2 primary outputs | Central unified data model |
| `skill_plan` | EXTERNAL TABLE | 4+ views | Curriculum skill definitions |
