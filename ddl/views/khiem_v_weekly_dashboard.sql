-- VIEW: studient.khiem_v_weekly_dashboard
-- Extracted from AWS Athena on 2026-03-29

CREATE OR REPLACE VIEW studient.khiem_v_weekly_dashboard AS
WITH
  alpha_student_dedup AS (
   -- Dedup alpha_student: 1 row per student, prefer row with group populated
   SELECT fullid, "group" AS student_group, advisoremail
   FROM (
     SELECT fullid, "group", advisoremail,
       ROW_NUMBER() OVER (PARTITION BY fullid
         ORDER BY CASE WHEN "group" IS NOT NULL AND "group" <> '' THEN 0 ELSE 1 END ASC
       ) rn
     FROM studient.alpha_student
     WHERE admissionstatus = 'Enrolled'
   )
   WHERE rn = 1
)
, sc_roster AS (
   SELECT DISTINCT
     r.full_student_id student_id
   , r.student_name
   , r.campus_id
   , r.campus_name
   , (CASE WHEN (r.campus_name LIKE '%Allendale Aspire%') THEN 'AASP' WHEN (r.campus_name LIKE '%Allendale Fairfax Elementary%') THEN 'AFES' WHEN (r.campus_name LIKE '%Allendale Fairfax Middle%') THEN 'AFMS' WHEN (r.campus_name LIKE '%Hardeeville Elementary%') THEN 'JHES' WHEN ((r.campus_name LIKE '%Hardeeville Junior%') OR (r.campus_name LIKE '%Hardeeville Secondary%')) THEN 'JHMS' WHEN (r.campus_name LIKE '%Ridgeland Elementary%') THEN 'JRES' WHEN (r.campus_name LIKE '%Ridgeland Secondary%') THEN 'JRHS' WHEN (r.campus_name LIKE '%Metro%') THEN 'Metro' WHEN (r.campus_name LIKE '%Science%') THEN 'Science SIS' WHEN (r.campus_name LIKE '%Vita%') THEN 'Vita' ELSE r.campus_name END) school_abbrev
   , (CASE WHEN (TRY_CAST(r.grade AS INTEGER) <= 5) THEN 'Elementary' WHEN (TRY_CAST(r.grade AS INTEGER) <= 8) THEN 'Middle School' ELSE 'High School' END) school_level
   , r.grade
   , r.teacher_name
   , COALESCE(ast.advisoremail, r.teacher_email) teacher_email
   , ast.advisoremail advisor_email
   , ast.student_group
   FROM
     (studient.khiem_v_roster r
   LEFT JOIN alpha_student_dedup ast ON (r.full_student_id = ast.fullid))
) 
, weeks AS (
   SELECT DISTINCT
     DATE_TRUNC('week', activity_date) week_start
   , CONCAT('Week of ', DATE_FORMAT(DATE_TRUNC('week', activity_date), '%m-%d-%y')) week_label
   FROM
     studient.khiem_v_lesson_unified
   WHERE (activity_date >= DATE '2025-08-01')
) 
, weekly_activity AS (
   SELECT
     DATE_TRUNC('week', activity_date) week_start
   , student_id
   , 1 had_activity
   , SUM(COALESCE(minutes_working, 0)) total_minutes
   , COUNT(DISTINCT CAST(activity_date AS DATE)) days_active
   , SUM((CASE WHEN ((is_test = true) AND (NOT (COALESCE(UPPER(test_source), '') IN ('NWEA', 'MAP'))) AND (test_type <> 'MAP')) THEN 1 ELSE 0 END)) tests_taken
   , SUM((CASE WHEN ((is_test = true) AND (NOT (COALESCE(UPPER(test_source), '') IN ('NWEA', 'MAP'))) AND (test_type <> 'MAP') AND (LOWER(COALESCE(test_result, '')) = 'pass')) THEN 1 ELSE 0 END)) tests_mastered
   , SUM(COALESCE(levels_mastered, 0)) lessons_mastered
   , SUM(COALESCE(essential_levels_mastered_eng, 0)) essential_lessons_mastered
   , MAX(onboarding_status) onboarding_status
   , MAX(knowledge_grade) knowledge_grade
   , MAX(subject) primary_subject
   FROM
     studient.khiem_v_lesson_unified
   WHERE (activity_date >= DATE '2025-08-01')
   GROUP BY 1, 2
) 
SELECT
  w.week_start
, w.week_label
, r.student_id
, r.student_name
, r.campus_id
, r.campus_name
, r.school_abbrev
, r.school_level
, r.grade
, r.teacher_name
, r.teacher_email
, r.advisor_email
, r.student_group
, COALESCE(a.had_activity, 0) logged_in
, COALESCE(a.total_minutes, 0) total_minutes
, COALESCE(a.days_active, 0) days_active
, COALESCE(a.tests_taken, 0) tests_taken
, COALESCE(a.tests_mastered, 0) tests_mastered
, COALESCE(a.lessons_mastered, 0) lessons_mastered
, COALESCE(a.essential_lessons_mastered, 0) essential_lessons_mastered
, COALESCE(a.knowledge_grade, 0) knowledge_grade
, a.primary_subject
, COALESCE(a.onboarding_status, 'Not Started') onboarding_status
, (CASE WHEN (a.onboarding_status = 'BRACKETING') THEN 1 ELSE 0 END) is_bracketing
, (CASE WHEN (a.onboarding_status = 'ONBOARDED') THEN 1 ELSE 0 END) is_onboarded
, (CASE WHEN (a.onboarding_status = 'ROSTERED') THEN 1 ELSE 0 END) is_rostered
, (CASE WHEN (a.onboarding_status IS NULL) THEN 1 ELSE 0 END) is_not_started
FROM
  ((sc_roster r
CROSS JOIN weeks w)
LEFT JOIN weekly_activity a ON ((r.student_id = a.student_id) AND (w.week_start = a.week_start)))
