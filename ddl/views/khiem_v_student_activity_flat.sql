-- VIEW: studient.khiem_v_student_activity_flat
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_student_activity_flat AS
WITH
  target_campuses AS (
   SELECT campus_id
   FROM
     (
 VALUES 
        '064'
      , '056'
      , '066'
      , '033'
      , '068'
      , '079'
   )  t (campus_id)
) 
SELECT
  'Activity' row_type
, false is_test
, dt.date activity_date
, r.full_student_id student_id
, r.student_name
, r.campus_id
, r.campus_name
, r.grade
, r.level
, r.teacher_name
, r.teacher_email
, dt.subject
, dt.app
, dt.course
, dt.daily_minutes minutes_working
, dt.units_mastered
, dt.correct_questions
, dt.total_questions
, dt.accuracy
, dt.antipatterns
, dt.antipattern_count
, dt.learning_level
, dt.learning_unit_passed
, COALESCE(ed.essential_units_attempted, 0) essential_units_attempted
, COALESCE(ed.essential_units_mastered, 0) essential_units_mastered
, COALESCE(ed.total_units_mastered_lm, 0) levels_mastered
, COALESCE(tgt.daily_mastery_target, 0) daily_mastery_target
, (CASE WHEN (COALESCE(tgt.daily_mastery_target, 0) > 0) THEN ROUND((CAST(COALESCE(ed.essential_units_mastered, 0) AS DOUBLE) / CAST(tgt.daily_mastery_target AS DOUBLE)), 4) ELSE null END) mastery_vs_daily_target_pct
, (COALESCE(ed.essential_units_mastered, 0) - COALESCE(tgt.daily_mastery_target, 0)) variance_vs_daily_target
, (CASE WHEN (COALESCE(tgt.daily_mastery_target, 0) = 0) THEN 'No Target' WHEN (COALESCE(ed.essential_units_mastered, 0) >= COALESCE(tgt.daily_mastery_target, 0)) THEN 'Met Target' ELSE 'Below Target' END) target_status
, CAST(null AS VARCHAR) lesson_name
, CAST(null AS VARCHAR) topic
, CAST(null AS REAL) mastery_percentage
, CAST(null AS VARCHAR) lesson_status
, CAST(null AS VARCHAR) resource_type
, CAST(null AS VARCHAR) test_source
, CAST(null AS VARCHAR) test_name
, CAST(null AS VARCHAR) test_type
, CAST(null AS DOUBLE) test_score
, CAST(null AS DOUBLE) test_max_score
, CAST(null AS DOUBLE) test_accuracy
, CAST(null AS VARCHAR) test_result
, nwea.fall_rit
, nwea.winter_rit
, nwea.spring_rit
, nwea.fall_cgp
, nwea.winter_cgp
, nwea.spring_cgp
, nwea.f2w_projected_growth
, nwea.f2w_observed_growth
, (CASE WHEN (TRY_CAST(nwea.f2w_projected_growth AS DOUBLE) > 0) THEN ROUND((TRY_CAST(nwea.f2w_observed_growth AS DOUBLE) / TRY_CAST(nwea.f2w_projected_growth AS DOUBLE)), 4) ELSE null END) x_growth
, bh.onboarding_status
, bh.knowledge_grade
FROM
  (((((studient.khiem_v_roster r
INNER JOIN studient.khiem_v_daily_time dt ON (r.full_student_id = dt.full_student_id))
LEFT JOIN studient.khiem_v_essential_units_daily ed ON ((dt.full_student_id = ed.full_student_id) AND (dt.date = ed.date) AND (LOWER(dt.subject) = LOWER(ed.subject)) AND (LOWER(dt.app) = LOWER(ed.app))))
LEFT JOIN studient.khiem_v_daily_targets tgt ON ((dt.full_student_id = tgt.full_student_id) AND (dt.date = tgt.date) AND (LOWER(dt.subject) = LOWER(tgt.subject)) AND (LOWER(dt.app) = LOWER(tgt.app))))
LEFT JOIN studient.khiem_v_nwea_comprehensive nwea ON ((r.full_student_id = nwea.full_student_id) AND (LOWER(dt.subject) = nwea.subject_lower)))
LEFT JOIN studient.khiem_v_bracketing_history_ranges bh ON ((r.full_student_id = bh.full_student_id) AND (LOWER(dt.subject) = bh.subject) AND (dt.date BETWEEN bh.valid_from_date AND bh.valid_to_date)))
WHERE ((dt.date >= DATE '2025-01-01') AND (r.campus_id IN (SELECT campus_id
FROM
  target_campuses
)))
UNION ALL SELECT
  'Test' row_type
, true is_test
, ts.date activity_date
, ts.student_id
, ts.student_name
, r.campus_id
, r.campus_name
, r.grade
, r.level
, r.teacher_name
, r.teacher_email
, ts.subject
, CAST(null AS VARCHAR) app
, CAST(null AS VARCHAR) course
, CAST(null AS DOUBLE) minutes_working
, CAST(null AS BIGINT) units_mastered
, CAST(null AS BIGINT) correct_questions
, CAST(null AS BIGINT) total_questions
, CAST(null AS DOUBLE) accuracy
, CAST(null AS VARCHAR) antipatterns
, CAST(null AS BIGINT) antipattern_count
, CAST(null AS VARCHAR) learning_level
, CAST(null AS VARCHAR) learning_unit_passed
, CAST(null AS BIGINT) essential_units_attempted
, CAST(null AS BIGINT) essential_units_mastered
, CAST(null AS BIGINT) levels_mastered
, CAST(null AS BIGINT) daily_mastery_target
, CAST(null AS DOUBLE) mastery_vs_daily_target_pct
, CAST(null AS BIGINT) variance_vs_daily_target
, CAST(null AS VARCHAR) target_status
, CAST(null AS VARCHAR) lesson_name
, CAST(null AS VARCHAR) topic
, CAST(null AS REAL) mastery_percentage
, CAST(null AS VARCHAR) lesson_status
, CAST(null AS VARCHAR) resource_type
, ts.source_system test_source
, ts.test_name
, ts.test_type
, ts.score test_score
, ts.max_score test_max_score
, ts.accuracy_pct test_accuracy
, ts.pass_fail test_result
, nwea.fall_rit
, nwea.winter_rit
, nwea.spring_rit
, nwea.fall_cgp
, nwea.winter_cgp
, nwea.spring_cgp
, nwea.f2w_projected_growth
, nwea.f2w_observed_growth
, (CASE WHEN (TRY_CAST(nwea.f2w_projected_growth AS DOUBLE) > 0) THEN ROUND((TRY_CAST(nwea.f2w_observed_growth AS DOUBLE) / TRY_CAST(nwea.f2w_projected_growth AS DOUBLE)), 4) ELSE null END) x_growth
, bh.onboarding_status
, bh.knowledge_grade
FROM
  (((studient.khiem_v_test_scores_final ts
INNER JOIN studient.khiem_v_roster r ON (ts.student_id = r.full_student_id))
LEFT JOIN studient.khiem_v_nwea_comprehensive nwea ON ((r.full_student_id = nwea.full_student_id) AND (LOWER(ts.subject) = nwea.subject_lower)))
LEFT JOIN studient.khiem_v_bracketing_history_ranges bh ON ((r.full_student_id = bh.full_student_id) AND (LOWER(ts.subject) = bh.subject) AND (ts.date BETWEEN bh.valid_from_date AND bh.valid_to_date)))
WHERE ((ts.date >= DATE '2025-01-01') AND (r.campus_id IN (SELECT campus_id
FROM
  target_campuses
)))
