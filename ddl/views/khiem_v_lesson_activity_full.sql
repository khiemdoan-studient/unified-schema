-- VIEW: studient.khiem_v_lesson_activity_full
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_lesson_activity_full AS
WITH
  roster AS (
   SELECT DISTINCT
     full_student_id
   , student_name
   , campus_id
   , campus_name
   , grade
   , level
   , teacher_name
   , teacher_email
   FROM
     studient.khiem_v_roster
) 
SELECT
  DATE(la.date) lesson_date
, CONCAT(LPAD(r.campus_id, 3, '0'), '-', LPAD(CAST(la.student_id AS VARCHAR), 4, '0')) full_student_id
, r.student_name
, r.campus_id
, r.campus_name
, r.grade
, r.level
, r.teacher_name
, r.teacher_email
, LOWER(la.subject) subject
, LOWER(la.app) app
, la.course
, la.topic
, la.lesson_name
, la.mastery_percentage
, la.activity_units_attempted
, la.activity_units_correct
, la.minutes
, la.status lesson_status
, la.resource_type
, la.lesson_url
FROM
  (studient.khiem_v_lesson_activity la
LEFT JOIN roster r ON (CONCAT(LPAD(r.campus_id, 3, '0'), '-', LPAD(CAST(la.student_id AS VARCHAR), 4, '0')) = r.full_student_id))
WHERE (DATE(la.date) >= DATE '2025-01-01')
