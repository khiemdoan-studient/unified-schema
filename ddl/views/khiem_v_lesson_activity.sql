-- VIEW: studient.khiem_v_lesson_activity
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_lesson_activity AS
SELECT
  CAST(lm.date AS DATE) date
, lm.external_student_id student_id
, lm.student
, lm.app
, lm.subject
, lm.course
, lm.topic
, lm.level lesson_name
, lm.mastery_percentage
, lm.activity_units_attempted
, lm.activity_units_correct
, lm.app_reported_time_minutes minutes
, lm.status
, lm.resource_type
, lm.url lesson_url
FROM
  studient.level_mastery lm
WHERE (lm.date IS NOT NULL)
