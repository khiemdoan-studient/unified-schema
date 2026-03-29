-- VIEW: studient.khiem_v_doom_loop_students
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_doom_loop_students AS
WITH
  test_events AS (
   SELECT
     student_id
   , student_name
   , campus_id
   , campus_name
   , school_name
   , student_group
   , grade enrolled_grade
   , level student_level
   , teacher_name
   , teacher_email
   , advisor_email
   , subject
   , LOWER(subject) subject_lower
   , knowledge_grade
   , onboarding_status
   , activity_date test_date
   , test_name
   , LOWER(test_result) test_result
   FROM
     studient.khiem_v_lesson_unified
   WHERE ((row_type = 'Test') AND (LOWER(test_source) = 'edulastic') AND (LOWER(test_result) IN ('fail', 'pass')) AND (activity_date >= DATE '2025-01-01'))
) 
, running_counts AS (
   SELECT
     *
   , SUM((CASE WHEN (test_result = 'fail') THEN 1 ELSE 0 END)) OVER (PARTITION BY student_id, subject_lower, knowledge_grade ORDER BY test_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cumulative_fail_count
   , MIN((CASE WHEN (test_result = 'pass') THEN test_date END)) OVER (PARTITION BY student_id, subject_lower, knowledge_grade) first_pass_date
   FROM
     test_events
) 
, doom_loop_windows AS (
   SELECT
     *
   , MIN((CASE WHEN (cumulative_fail_count = 3) THEN test_date END)) OVER (PARTITION BY student_id, subject_lower, knowledge_grade) doom_loop_entry_date
   , (CASE WHEN ((first_pass_date IS NOT NULL) AND (first_pass_date >= MIN((CASE WHEN (cumulative_fail_count = 3) THEN test_date END)) OVER (PARTITION BY student_id, subject_lower, knowledge_grade))) THEN first_pass_date ELSE null END) doom_loop_exit_date
   FROM
     running_counts
) 
SELECT DISTINCT
  student_id
, student_name
, campus_id
, campus_name
, school_name
, student_group
, enrolled_grade
, student_level
, teacher_name
, teacher_email
, advisor_email
, subject
, subject_lower
, knowledge_grade
, onboarding_status
, MAX(cumulative_fail_count) OVER (PARTITION BY student_id, subject_lower, knowledge_grade) total_fail_count
, doom_loop_entry_date
, doom_loop_exit_date
, (CASE WHEN (doom_loop_entry_date IS NOT NULL) THEN 'Entered Doom Loop' WHEN (MAX(cumulative_fail_count) OVER (PARTITION BY student_id, subject_lower, knowledge_grade) = 2) THEN 'At Risk' ELSE 'Monitoring' END) overall_status
, (doom_loop_entry_date IS NOT NULL) ever_in_doom_loop
, (doom_loop_exit_date IS NOT NULL) has_exited
FROM
  doom_loop_windows
WHERE (test_date = (SELECT MAX(t2.test_date)
FROM
  doom_loop_windows t2
WHERE ((t2.student_id = doom_loop_windows.student_id) AND (t2.subject_lower = doom_loop_windows.subject_lower) AND (t2.knowledge_grade = doom_loop_windows.knowledge_grade))
))
