-- VIEW: studient.khiem_v_student_progress_metrics
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_student_progress_metrics AS
WITH
  student_totals AS (
   SELECT
     sep.student_id
   , sep.subject
   , sep.app
   , SUM(sep.essential_levels_mastered_eng) total_essential_mastered
   , SUM(sep.total_essential_skills) total_essential_skills
   , SUM(sep.essential_remaining) total_essential_remaining
   FROM
     studient.khiem_v_student_essential_progress sep
   GROUP BY sep.student_id, sep.subject, sep.app
) 
, school_year_params AS (
   SELECT
     DATE '2025-01-01' school_year_start
   , 180 total_school_days
   , DATE_DIFF('day', DATE '2025-01-01', current_date) days_elapsed

) 
SELECT
  st.student_id
, st.subject
, st.app
, st.total_essential_mastered
, st.total_essential_skills
, st.total_essential_remaining
, (CASE WHEN (st.total_essential_skills > 0) THEN ROUND(((CAST(st.total_essential_mastered AS DOUBLE) / st.total_essential_skills) * 100), 2) ELSE 0 END) pct_complete
, ROUND(((CAST(st.total_essential_skills AS DOUBLE) * 2E0) / syp.total_school_days), 2) daily_target_2x
, ROUND((((CAST(st.total_essential_skills AS DOUBLE) * 2E0) / syp.total_school_days) * 5), 2) weekly_target_2x
, ROUND((((CAST(st.total_essential_skills AS DOUBLE) * 2E0) / syp.total_school_days) * syp.days_elapsed), 2) expected_mastery_2x
, (CASE WHEN ((((CAST(st.total_essential_skills AS DOUBLE) * 2E0) / syp.total_school_days) * syp.days_elapsed) > 0) THEN ROUND((CAST(st.total_essential_mastered AS DOUBLE) / (((CAST(st.total_essential_skills AS DOUBLE) * 2E0) / syp.total_school_days) * syp.days_elapsed)), 2) ELSE null END) x_growth_ratio
, GREATEST(0, ROUND(((((CAST(st.total_essential_skills AS DOUBLE) * 2E0) / syp.total_school_days) * syp.days_elapsed) - st.total_essential_mastered), 0)) lessons_to_catchup_2x
, syp.days_elapsed
, syp.total_school_days
FROM
  (student_totals st
CROSS JOIN school_year_params syp)
