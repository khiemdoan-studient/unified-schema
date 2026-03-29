-- VIEW: studient.khiem_v_student_lessons
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_student_lessons AS
SELECT
  id
, mastered_at
, topic_mastery_id
, CAST(mastered_at AS DATE) date
, student student_name
, external_student_id full_student_id
, app
, subject
, course
, topic
, level
, mastery_percentage
, activity_units_attempted
, activity_units_correct
, app_reported_time_minutes
, app_specific_data
, url
, third_party_level_id
, resource_type
, active_minutes
, status
FROM
  studient.level_mastery
WHERE (status IS NOT NULL)
