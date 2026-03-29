-- VIEW: studient.khiem_v_daily_essential_mastery
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_daily_essential_mastery AS
WITH
  ixl_daily AS (
   SELECT
     full_student_id student_id
   , CAST(date AS DATE) activity_date
   , subject
   , app
   , COUNT(DISTINCT skill_id) essential_mastered_today
   FROM
     studient.khiem_v_student_ixl_essential_mastery
   GROUP BY full_student_id, date, subject, app
) 
, edulastic_daily AS (
   SELECT
     external_student_id student_id
   , CAST(date AS DATE) activity_date
   , subject
   , app
   , COUNT(DISTINCT skill_id) essential_mastered_today
   FROM
     studient.khiem_v_student_edulastic_essential_mastery
   GROUP BY external_student_id, date, subject, app
) 
SELECT *
FROM
  ixl_daily
UNION ALL SELECT *
FROM
  edulastic_daily
