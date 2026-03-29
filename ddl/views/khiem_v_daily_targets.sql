-- VIEW: studient.khiem_v_daily_targets
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_daily_targets AS
WITH
  ranked_targets AS (
   SELECT
     dt.date
   , dt.full_student_id
   , dt.subject
   , dt.app
   , r.grade
   , TRY_CAST(mt.target_mastery_units AS INTEGER) daily_mastery_target
   , ROW_NUMBER() OVER (PARTITION BY dt.date, dt.full_student_id, dt.subject, dt.app ORDER BY (CASE WHEN ((mt.grade IS NOT NULL) AND (mt.grade <> '') AND (CAST(r.grade AS VARCHAR) = mt.grade)) THEN 0 ELSE 1 END) ASC, TRY_CAST(mt.target_mastery_units AS INTEGER) DESC) rn
   FROM
     ((studient.khiem_v_daily_time dt
   INNER JOIN studient.khiem_v_roster r ON (dt.full_student_id = r.full_student_id))
   LEFT JOIN studient.mastery_thresholds mt ON ((LPAD(CAST(r.campus_id AS VARCHAR), 3, '0') = LPAD(mt.campus_id, 3, '0')) AND (LOWER(dt.app) = LOWER(mt.app)) AND (LOWER(dt.subject) = LOWER(mt.subject)) AND ((CAST(r.grade AS VARCHAR) = mt.grade) OR (mt.grade IS NULL) OR (mt.grade = ''))))
   WHERE (dt.date >= DATE '2025-01-01')
) 
SELECT
  date
, full_student_id
, subject
, app
, grade
, daily_mastery_target
FROM
  ranked_targets
WHERE (rn = 1)
