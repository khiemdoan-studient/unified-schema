-- VIEW: studient.khiem_v_student_essential_mastery_from_lm
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_student_essential_mastery_from_lm AS
WITH
  roster_dedup AS (
   SELECT
     full_student_id
   , LPAD(SUBSTRING(full_student_id, 5), 4, '0') external_student_id
   , ROW_NUMBER() OVER (PARTITION BY LPAD(SUBSTRING(full_student_id, 5), 4, '0') ORDER BY full_student_id ASC) rn
   FROM
     studient.khiem_v_roster
) 
, roster AS (
   SELECT
     full_student_id
   , external_student_id
   FROM
     roster_dedup
   WHERE (rn = 1)
) 
, ixl_mastery AS (
   SELECT
     r.full_student_id student_id
   , CAST(lm.date AS DATE) activity_date
   , (CASE WHEN (lm.subject = 'Reading') THEN 'Language' ELSE lm.subject END) subject
   , LOWER(lm.app) app
   , SUM((CASE WHEN ((LOWER(COALESCE(lm.resource_type, '')) = 'essential') AND (LOWER(COALESCE(lm.status, '')) IN ('completed', 'mastered', 'passed'))) THEN 1 ELSE 0 END)) essential_levels_mastered_eng
   FROM
     (studient.level_mastery lm
   INNER JOIN roster r ON (LPAD(lm.external_student_id, 4, '0') = r.external_student_id))
   WHERE ((LOWER(lm.app) = 'ixl') AND (lm.date >= DATE '2025-01-01'))
   GROUP BY 1, 2, 3, 4
) 
, non_ixl_mastery AS (
   SELECT
     r.full_student_id student_id
   , CAST(dlm.date AS DATE) activity_date
   , (CASE WHEN (dlm.subject = 'Reading') THEN 'Language' ELSE dlm.subject END) subject
   , LOWER(dlm.app) app
   , SUM(COALESCE(dlm.levels_mastered, 0)) essential_levels_mastered_eng
   FROM
     (studient.daily_learning_metrics dlm
   INNER JOIN roster r ON (LPAD(dlm.external_student_id, 4, '0') = r.external_student_id))
   WHERE ((LOWER(dlm.app) <> 'ixl') AND (dlm.date >= DATE '2025-01-01'))
   GROUP BY 1, 2, 3, 4
) 
SELECT *
FROM
  ixl_mastery
UNION ALL SELECT *
FROM
  non_ixl_mastery
