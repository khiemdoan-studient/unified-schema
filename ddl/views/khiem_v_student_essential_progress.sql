-- VIEW: studient.khiem_v_student_essential_progress
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_student_essential_progress AS
WITH
  ixl_mastery AS (
   SELECT
     full_student_id student_id
   , CAST(date AS DATE) mastery_date
   , subject
   , app
   , skill_id
   , plan_grade
   , 1 essential_mastered
   FROM
     studient.khiem_v_student_ixl_essential_mastery
) 
, edulastic_mastery AS (
   SELECT
     external_student_id student_id
   , CAST(date AS DATE) mastery_date
   , subject
   , app
   , skill_id
   , plan_grade
   , 1 essential_mastered
   FROM
     studient.khiem_v_student_edulastic_essential_mastery
) 
, combined_mastery AS (
   SELECT *
   FROM
     ixl_mastery
UNION ALL    SELECT *
   FROM
     edulastic_mastery
) 
, distinct_mastery AS (
   SELECT DISTINCT
     student_id
   , subject
   , app
   , skill_id
   , plan_grade
   , MIN(mastery_date) first_mastery_date
   FROM
     combined_mastery
   GROUP BY student_id, subject, app, skill_id, plan_grade
) 
SELECT
  dm.student_id
, dm.subject
, dm.app
, dm.plan_grade
, COUNT(DISTINCT dm.skill_id) essential_levels_mastered_eng
, esc.total_essential_skills
, (CASE WHEN (esc.total_essential_skills > 0) THEN ROUND(((CAST(COUNT(DISTINCT dm.skill_id) AS DOUBLE) / esc.total_essential_skills) * 100), 2) ELSE 0 END) pct_essential_complete
, (COALESCE(esc.total_essential_skills, 0) - COUNT(DISTINCT dm.skill_id)) essential_remaining
FROM
  (distinct_mastery dm
LEFT JOIN studient.khiem_v_essential_skill_counts esc ON ((LOWER(dm.app) = LOWER(esc.app)) AND (LOWER(dm.subject) = LOWER(esc.subject)) AND (dm.plan_grade = esc.plan_grade)))
GROUP BY dm.student_id, dm.subject, dm.app, dm.plan_grade, esc.total_essential_skills
