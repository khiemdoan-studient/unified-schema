-- VIEW: studient.khiem_v_bracketing_history_ranges
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_bracketing_history_ranges AS
WITH
  normalized AS (
   SELECT
     full_student_id
   , LOWER(trim(BOTH FROM subject)) subject
   , subject bracketing_subject_raw
   , grade knowledge_grade
   , age_grade
   , onboarding_status
   , notes
   , TRY(CAST(from_iso8601_timestamp(assigned_on) AS DATE)) valid_from_date
   , TRY(CAST(from_iso8601_timestamp(NULLIF(trim(BOTH FROM invalidated_on), '')) AS DATE)) invalidated_date
   FROM
     studient.bracketing_assignments
   WHERE ((assigned_on IS NOT NULL) AND (full_student_id IS NOT NULL) AND (trim(BOTH FROM full_student_id) <> ''))
) 
, deduped AS (
   SELECT *
   FROM
     (
      SELECT
        *
      , ROW_NUMBER() OVER (PARTITION BY full_student_id, subject, valid_from_date ORDER BY COALESCE(invalidated_date, DATE '2099-12-31') DESC) rn
      FROM
        normalized
   ) 
   WHERE (rn = 1)
) 
, ranged AS (
   SELECT
     full_student_id
   , subject
   , bracketing_subject_raw
   , knowledge_grade
   , age_grade
   , onboarding_status
   , notes
   , valid_from_date
   , LEAST(COALESCE(invalidated_date, DATE '2099-12-31'), COALESCE((LEAD(valid_from_date) OVER (PARTITION BY full_student_id, subject ORDER BY valid_from_date ASC) - INTERVAL  '1' DAY), DATE '2099-12-31')) valid_to_date
   FROM
     deduped
) 
SELECT *
FROM
  ranged
WHERE (valid_to_date >= valid_from_date)
