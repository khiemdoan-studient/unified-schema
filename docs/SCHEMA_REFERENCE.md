# Schema Reference — All Views

Complete column-level reference for every view in the `studient` database.

---

## Primary Output Views

### `khiem_v_lesson_unified`

The central unified view. Combines 4 record types via UNION ALL.

| Column | Type | Description | Source |
|--------|------|-------------|--------|
| `row_type` | VARCHAR | `Lesson`, `Activity`, `Test`, `Bracketing Assignment` | Hardcoded per UNION branch |
| `is_test` | BOOLEAN | TRUE for Test records | Hardcoded |
| `activity_date` | DATE | Date of the event | `level_mastery.date` / `daily_time.date` / test date / assignment date |
| `student_id` | VARCHAR | Full student ID (campus-ext format) | `khiem_v_roster.full_student_id` |
| `student_name` | VARCHAR | Student full name | `khiem_v_roster.student_name` |
| `campus_id` | VARCHAR | 3-digit campus code | `khiem_v_roster.campus_id` |
| `campus_name` | VARCHAR | Full campus name | `khiem_v_roster.campus_name` |
| `school_name` | VARCHAR | School/group name | `COALESCE(alpha_student.group, campus_name)` |
| `student_group` | VARCHAR | Student group string | `alpha_student.group` |
| `grade` | VARCHAR | Enrolled grade | `khiem_v_roster.grade` |
| `level` | VARCHAR | School level (Elem/Middle/High) | `khiem_v_roster.level` |
| `teacher_name` | VARCHAR | Teacher name | `khiem_v_roster.teacher_name` |
| `teacher_email` | VARCHAR | Teacher email | `khiem_v_roster.teacher_email` |
| `advisor_email` | VARCHAR | Advisor email | `alpha_student.advisoremail` |
| `subject_display` | VARCHAR | Subject with proper casing | Computed |
| `subject` | VARCHAR | Normalized subject | Computed (Reading, Language, Math, etc.) |
| `app` | VARCHAR | Learning app name | `level_mastery.app` / `daily_time.app` |
| `course` | VARCHAR | Course name | `level_mastery.course` |
| `minutes_raw` | DOUBLE | Raw active minutes | `level_mastery.active_minutes` |
| `minutes_working` | DOUBLE | Deduplicated minutes (first row per student/date/app gets minutes) | Computed via ROW_NUMBER |
| `units_mastered` | INTEGER | Units mastered | `level_mastery.activity_units_correct` (if mastered) |
| `correct_questions` | INTEGER | Correct answers | `level_mastery.activity_units_correct` |
| `total_questions` | INTEGER | Total questions attempted | `level_mastery.activity_units_attempted` |
| `accuracy` | DOUBLE | Accuracy percentage | Computed: `correct / total * 100` |
| `levels_mastered` | INTEGER | 1 if lesson mastered, 0 otherwise | `is_mastered` flag |
| `essential_units_attempted` | INTEGER | Essential units attempted | `is_essential * activity_units_attempted` |
| `essential_units_mastered` | INTEGER | Essential units mastered | `is_essential * is_mastered` |
| `daily_mastery_target` | INTEGER | Daily mastery target | `khiem_v_daily_targets.target` |
| `mastery_vs_daily_target_pct` | DOUBLE | Mastery as % of daily target | Computed |
| `variance_vs_daily_target` | INTEGER | Units above/below target | Computed |
| `target_status` | VARCHAR | `On Target`, `Below Target`, `Above Target` | Computed |
| `lesson_name` | VARCHAR | Level/lesson name | `level_mastery.level` |
| `topic` | VARCHAR | Topic name | `level_mastery.topic` |
| `mastery_percentage` | DOUBLE | Mastery % | `level_mastery.mastery_percentage` |
| `lesson_status` | VARCHAR | completed, mastered, passed, etc. | `level_mastery.status` |
| `resource_type` | VARCHAR | essential or standard | `level_mastery.resource_type` |
| `lesson_url` | VARCHAR | URL to lesson | `level_mastery.url` |
| `lesson_id` | VARCHAR | Lesson record ID | `level_mastery.id` |
| `lesson_rn` | INTEGER | Lesson row number per student/date/subject/app | ROW_NUMBER |
| `test_source` | VARCHAR | Test source system | `khiem_v_test_scores_final.source_system` |
| `test_name` | VARCHAR | Test title | `khiem_v_test_scores_final.test_name` |
| `test_type` | VARCHAR | Test type | `edulastic_test_inventory` or computed |
| `test_score` | DOUBLE | Test score | `khiem_v_test_scores_final.score` |
| `test_max_score` | DOUBLE | Test max score | `khiem_v_test_scores_final.max_score` |
| `test_accuracy` | DOUBLE | Test accuracy | `khiem_v_test_scores_final.accuracy` |
| `test_result` | VARCHAR | Pass or Fail | `khiem_v_test_scores_final.pass_fail` |
| `fall_rit` | INTEGER | NWEA Fall RIT score | `khiem_v_nwea_comprehensive` |
| `winter_rit` | INTEGER | NWEA Winter RIT score | `khiem_v_nwea_comprehensive` |
| `spring_rit` | INTEGER | NWEA Spring RIT score | `khiem_v_nwea_comprehensive` |
| `fall_cgp` | INTEGER | NWEA Fall CGP | `khiem_v_nwea_comprehensive` |
| `winter_cgp` | INTEGER | NWEA Winter CGP | `khiem_v_nwea_comprehensive` |
| `spring_cgp` | INTEGER | NWEA Spring CGP | `khiem_v_nwea_comprehensive` |
| `f2w_projected_growth` | VARCHAR | Fall→Winter projected growth | `khiem_v_nwea_comprehensive` |
| `f2w_observed_growth` | VARCHAR | Fall→Winter observed growth | `khiem_v_nwea_comprehensive` |
| `map_growth_score` | DOUBLE | MAP growth metric | Computed: `observed - projected` |
| `essential_levels_mastered_eng` | INTEGER | Daily essential levels mastered | `khiem_v_student_essential_mastery_from_lm` |
| `total_mastered_essential_levels_eng` | INTEGER | Running total essential mastered | Cumulative window SUM |
| `avg_essential_lessons_hardcoded` | DOUBLE | Avg daily essential mastery needed | Computed from total / remaining days |
| `avg_essential_lessons_quicksight` | DOUBLE | Avg for QuickSight targets | Computed |
| `grade_completion_target_day` | DOUBLE | Daily target to complete grade | Computed |
| `grade_completion_target_day_quicksight` | DOUBLE | QuickSight version of target | Computed |
| `total_course_essential_levels_eng` | INTEGER | Total essential levels in course | `khiem_v_course_essential_totals` |
| `onboarding_status` | VARCHAR | ROSTERED / BRACKETING / ONBOARDED / Not Started | `khiem_v_bracketing_history_ranges` |
| `knowledge_grade` | INTEGER | Current knowledge grade | `khiem_v_bracketing_history_ranges` |
| `knowledge_grade_label` | VARCHAR | Display label for knowledge grade | Computed |
| `grade_source` | VARCHAR | Where grade came from | Computed |
| `test_group_key` | VARCHAR | Key for grouping tests | Computed |
| `days_since_assignment` | INTEGER | Days since bracketing assignment | Computed |
| `is_active_assignment` | BOOLEAN | Whether assignment is still active | Computed based on recent test activity |
| `notes` | VARCHAR | Additional notes | Computed |
| `x_growth` | DOUBLE | Growth multiplier | Computed |
| `antipatterns` | VARCHAR | Detected antipatterns | Computed |
| `antipattern_count` | INTEGER | Number of antipatterns | Computed |
| `learning_level` | VARCHAR | Current learning level | Computed |
| `learning_unit_passed` | INTEGER | Whether learning unit was passed | Computed |
| `dedupe_rn` | INTEGER | Deduplication row number (keep = 1) | ROW_NUMBER |

---

### `khiem_v_weekly_dashboard`

| Column | Type | Description |
|--------|------|-------------|
| `week_start` | DATE | Monday of the week |
| `week_label` | VARCHAR | "Week of MM-DD-YY" |
| `student_id` | VARCHAR | Full student ID |
| `student_name` | VARCHAR | Student name |
| `campus_id` | VARCHAR | Campus ID |
| `campus_name` | VARCHAR | Full campus name |
| `school_abbrev` | VARCHAR | Short name (JHES, JRES, JHMS, JRHS, AFES, AFMS, AASP, Metro, Reading Community) |
| `school_level` | VARCHAR | Elementary / Middle School / High School |
| `grade` | VARCHAR | Enrolled grade |
| `teacher_name` | VARCHAR | Teacher name |
| `teacher_email` | VARCHAR | Teacher or advisor email |
| `advisor_email` | VARCHAR | Advisor email |
| `student_group` | VARCHAR | Student group string |
| `logged_in` | INTEGER | 1 if had any activity that week, 0 otherwise |
| `total_minutes` | DOUBLE | Total minutes worked that week |
| `days_active` | INTEGER | Count of distinct active days (0-5) |
| `tests_taken` | INTEGER | Tests taken (excludes NWEA/MAP) |
| `tests_mastered` | INTEGER | Tests passed |
| `lessons_mastered` | INTEGER | Levels/lessons mastered |
| `essential_lessons_mastered` | INTEGER | Essential lessons mastered |
| `knowledge_grade` | INTEGER | Current knowledge grade |
| `primary_subject` | VARCHAR | Primary subject for the week |
| `onboarding_status` | VARCHAR | ROSTERED / BRACKETING / ONBOARDED / Not Started |
| `is_bracketing` | INTEGER | 1 if BRACKETING |
| `is_onboarded` | INTEGER | 1 if ONBOARDED |
| `is_rostered` | INTEGER | 1 if ROSTERED |
| `is_not_started` | INTEGER | 1 if no onboarding_status |

---

### `khiem_v_doom_loop_students`

| Column | Type | Description |
|--------|------|-------------|
| `student_id` | VARCHAR | Full student ID |
| `student_name` | VARCHAR | Student name |
| `campus_id` | VARCHAR | Campus ID |
| `campus_name` | VARCHAR | Campus name |
| `school_name` | VARCHAR | School/group name |
| `student_group` | VARCHAR | Student group |
| `enrolled_grade` | VARCHAR | Enrolled grade |
| `student_level` | VARCHAR | School level |
| `teacher_name` | VARCHAR | Teacher |
| `teacher_email` | VARCHAR | Teacher email |
| `advisor_email` | VARCHAR | Advisor email |
| `subject` | VARCHAR | Test subject (display casing) |
| `subject_lower` | VARCHAR | Lowercase subject |
| `knowledge_grade` | INTEGER | Knowledge grade being tested |
| `onboarding_status` | VARCHAR | Onboarding status |
| `total_fail_count` | INTEGER | Max cumulative failures for this subject/grade |
| `doom_loop_entry_date` | DATE | Date cumulative failures first reached 3 (NULL if never) |
| `doom_loop_exit_date` | DATE | First pass date after doom loop entry (NULL if still stuck) |
| `overall_status` | VARCHAR | "Entered Doom Loop" / "At Risk" / "Monitoring" |
| `ever_in_doom_loop` | BOOLEAN | TRUE if doom_loop_entry_date is not null |
| `has_exited` | BOOLEAN | TRUE if doom_loop_exit_date is not null |

---

## Intermediate Views

### `khiem_v_roster`

Deduplicated to 1 row per `full_student_id`. Filtered to `admissionstatus = 'Enrolled'` only. Uses `ROW_NUMBER` with `group`-populated preference as tiebreaker.

| Column | Type | Description |
|--------|------|-------------|
| `full_student_id` | VARCHAR | Full student ID (PK, unique after dedup) |
| `campus_id` | VARCHAR | 3-digit campus code |
| `external_student_id` | VARCHAR | Short student ID |
| `student_name` | VARCHAR | Student full name |
| `grade` | VARCHAR | Grade level |
| `age_grade` | VARCHAR | Alpha level short |
| `level` | VARCHAR | School level |
| `teacher_name` | VARCHAR | Teacher/advisor name |
| `campus_name` | VARCHAR | Campus name |
| `status` | VARCHAR | Admission status (always 'Enrolled') |
| `student_email` | VARCHAR | Student email |
| `teacher_email` | VARCHAR | Teacher email |

### `khiem_v_daily_time`

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Activity date |
| `full_student_id` | VARCHAR | Full student ID |
| `subject` | VARCHAR | Subject |
| `app` | VARCHAR | App name |
| `daily_minutes` | DOUBLE | Total daily minutes |
| `units_mastered` | INTEGER | Units mastered |
| `accuracy` | DOUBLE | Accuracy % |
| `course` | VARCHAR | Course name |

### `khiem_identity_bridge`

| Column | Type | Description |
|--------|------|-------------|
| `fullid` | VARCHAR | Full student ID (resolved) |
| `external_id_4` | VARCHAR | Last 4 digits of external ID |
| `bridge_type` | VARCHAR | Resolution method: UUID, EMAIL, EXTID, ROSTER |
| `student_name` | VARCHAR | Resolved student name |
| `email_norm` | VARCHAR | Normalized email |

### `khiem_v_test_scores_final`

| Column | Type | Description |
|--------|------|-------------|
| `student_id` | VARCHAR | Full student ID |
| `date` | DATE | Test date |
| `student_name` | VARCHAR | Student name |
| `test_name` | VARCHAR | Test title |
| `subject` | VARCHAR | Subject |
| `score` | DOUBLE | Score |
| `max_score` | DOUBLE | Max possible score |
| `accuracy` | DOUBLE | Accuracy % |
| `pass_fail` | VARCHAR | Pass or Fail |
| `source_system` | VARCHAR | edulastic, coachbot, or nwea |

### `khiem_v_nwea_comprehensive`

| Column | Type | Description |
|--------|------|-------------|
| `full_student_id` | VARCHAR | Full student ID |
| `subject_lower` | VARCHAR | Subject (lowercase) |
| `fall_rit` | INTEGER | Fall RIT score |
| `winter_rit` | INTEGER | Winter RIT score |
| `spring_rit` | INTEGER | Spring RIT score |
| `fall_cgp` | INTEGER | Fall Conditional Growth Percentile |
| `winter_cgp` | INTEGER | Winter CGP |
| `spring_cgp` | INTEGER | Spring CGP |
| `f2w_projected_growth` | VARCHAR | Fall→Winter projected growth |
| `f2w_observed_growth` | VARCHAR | Fall→Winter observed growth |

### `khiem_v_bracketing_history_ranges`

| Column | Type | Description |
|--------|------|-------------|
| `full_student_id` | VARCHAR | Full student ID |
| `subject` | VARCHAR | Subject |
| `knowledge_grade` | INTEGER | Knowledge grade assigned |
| `onboarding_status` | VARCHAR | ROSTERED / BRACKETING / ONBOARDED |
| `valid_from_date` | DATE | Range start date |
| `valid_to_date` | DATE | Range end date (NULL = current) |

### `khiem_v_essential_skill_counts`

| Column | Type | Description |
|--------|------|-------------|
| `app` | VARCHAR | App name |
| `subject` | VARCHAR | Subject |
| `plan_grade` | VARCHAR | Grade text (e.g., "Fifth grade") |
| `total_essential_skills` | INTEGER | Total essential skills for that grade |

### `khiem_v_full_skill_plan`

| Column | Type | Description |
|--------|------|-------------|
| `app` | VARCHAR | App name |
| `subject` | VARCHAR | Subject |
| `skill_id` | VARCHAR | Skill ID |
| `skill_code` | VARCHAR | Skill code |
| `plan_grade` | VARCHAR | Grade |
| `type` | VARCHAR | essential or supporting |

### `khiem_v_course_essential_totals`

| Column | Type | Description |
|--------|------|-------------|
| `app` | VARCHAR | App name |
| `subject` | VARCHAR | Subject |
| `course` | VARCHAR | Course name |
| `total_course_essential_levels` | INTEGER | Essential levels in this course |

### `khiem_v_daily_targets`

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Activity date |
| `full_student_id` | VARCHAR | Full student ID |
| `subject` | VARCHAR | Subject |
| `app` | VARCHAR | App name |
| `daily_mastery_target` | INTEGER | Target units to master per day |

### `khiem_v_student_essential_mastery_from_lm`

| Column | Type | Description |
|--------|------|-------------|
| `student_id` | VARCHAR | Full student ID |
| `activity_date` | DATE | Date |
| `subject` | VARCHAR | Subject |
| `app` | VARCHAR | App name |
| `essential_levels_mastered_eng` | INTEGER | Essential levels mastered that day |

### `khiem_v_daily_essential_mastery`

| Column | Type | Description |
|--------|------|-------------|
| `student_id` | VARCHAR | Full student ID |
| `activity_date` | DATE | Date |
| `subject` | VARCHAR | Subject |
| `app` | VARCHAR | App name |
| `essential_mastered_today` | INTEGER | Essential skills mastered that day |

### `khiem_v_essential_units_daily`

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Activity date |
| `full_student_id` | VARCHAR | Full student ID |
| `subject` | VARCHAR | Subject |
| `app` | VARCHAR | App name |
| `essential_units_attempted` | INTEGER | Essential units attempted |
| `essential_units_mastered` | INTEGER | Essential units mastered |

### `khiem_v_student_essential_progress`

| Column | Type | Description |
|--------|------|-------------|
| `student_id` | VARCHAR | Full student ID |
| `subject` | VARCHAR | Subject |
| `app` | VARCHAR | App name |
| `plan_grade` | VARCHAR | Grade |
| `essential_levels_mastered_eng` | INTEGER | Essential levels mastered |
| `total_essential_skills` | INTEGER | Total essential skills |
| `pct_essential_complete` | DOUBLE | Completion percentage |

### `khiem_v_student_progress_metrics`

| Column | Type | Description |
|--------|------|-------------|
| `student_id` | VARCHAR | Full student ID |
| `subject` | VARCHAR | Subject |
| `app` | VARCHAR | App name |
| `pct_complete` | DOUBLE | Completion % |
| `daily_target_2x` | DOUBLE | 2x growth daily target |
| `x_growth_ratio` | DOUBLE | Current growth ratio |
| `lessons_to_catchup_2x` | DOUBLE | Lessons needed for 2x catch-up |

### `khiem_v_rls_teacher_students`

| Column | Type | Description |
|--------|------|-------------|
| `teacher_email` | VARCHAR | Teacher email |
| `student_id` | VARCHAR | Full student ID |
| `campus_id` | VARCHAR | Campus ID |

### `khiem_v_student_activity_flat`

Legacy unified view (predecessor to `khiem_v_lesson_unified`). Similar structure but uses `khiem_v_essential_units_daily` instead of `khiem_v_student_essential_mastery_from_lm`.

### `khiem_v_lesson_activity` / `khiem_v_lesson_activity_full` / `khiem_v_lesson_detail` / `khiem_v_student_lessons`

Simple extractions from `level_mastery` with varying levels of roster enrichment. Used for ad-hoc analysis and QuickSight.
