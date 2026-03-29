-- VIEW: studient.khiem_v_daily_time
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_daily_time AS
SELECT
  date
, full_student_id
, subject
, app
, SUM(daily_minutes) daily_minutes
, SUM(units_mastered) units_mastered
, SUM(correct_questions) correct_questions
, SUM(total_questions) total_questions
, (CASE WHEN (SUM(total_questions) > 0) THEN ROUND((CAST(SUM(correct_questions) AS DOUBLE) / SUM(total_questions)), 4) ELSE null END) accuracy
, MAX(antipatterns) antipatterns
, SUM(antipattern_count) antipattern_count
, MAX(learning_level) learning_level
, MAX(learning_unit_passed) learning_unit_passed
, MAX(course) course
FROM
  (
   SELECT
     CAST(dlm.date AS DATE) date
   , CONCAT(LPAD(CAST(dlm.campus_id AS VARCHAR), 3, '0'), '-', CAST(dlm.external_student_id AS VARCHAR)) full_student_id
   , dlm.subject
   , dlm.app
   , dlm.course
   , COALESCE(TRY_CAST(dlm.active_minutes AS DOUBLE), 0) daily_minutes
   , COALESCE(TRY_CAST(dlm.levels_mastered AS INTEGER), 0) units_mastered
   , COALESCE(TRY_CAST(dlm.correct_questions AS INTEGER), 0) correct_questions
   , COALESCE(TRY_CAST(dlm.total_questions_attempted AS INTEGER), 0) total_questions
   , dlm.antipattern_finding_names antipatterns
   , COALESCE(TRY_CAST(dlm.antipattern_count AS INTEGER), 0) antipattern_count
   , dlm.learning_level
   , dlm.learning_unit_passed
   FROM
     studient.daily_learning_metrics dlm
)  base
GROUP BY 1, 2, 3, 4
