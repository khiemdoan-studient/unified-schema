-- VIEW: studient.khiem_v_lesson_detail
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_lesson_detail AS
SELECT
  r.full_student_id
, r.student_name
, r.campus_id
, r.campus_name
, r.grade
, r.level student_level
, r.teacher_name
, r.teacher_email
, lm.id lesson_id
, lm.mastered_at
, lm.topic_mastery_id
, CAST(lm.date AS DATE) lesson_date
, lm.student student_name_source
, lm.external_student_id
, lm.app
, lm.subject
, lm.course
, lm.topic
, lm.level lesson_name
, TRY_CAST(lm.mastery_percentage AS DOUBLE) mastery_percentage
, TRY_CAST(lm.activity_units_attempted AS INTEGER) activity_units_attempted
, TRY_CAST(lm.activity_units_correct AS INTEGER) activity_units_correct
, TRY_CAST(lm.app_reported_time_minutes AS DOUBLE) app_reported_time_minutes
, lm.app_specific_data
, lm.url lesson_url
, lm.third_party_level_id
, lm.resource_type
, TRY_CAST(lm.active_minutes AS DOUBLE) active_minutes
, lm.status
FROM
  (studient.level_mastery lm
INNER JOIN studient.khiem_v_roster r ON (LPAD(lm.external_student_id, 4, '0') = SUBSTRING(r.full_student_id, 5)))
WHERE ((lm.date >= DATE '2025-01-01') AND REGEXP_LIKE(lm.external_student_id, '^[0-9]+$'))
