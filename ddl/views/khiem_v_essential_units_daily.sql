-- VIEW: studient.khiem_v_essential_units_daily
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_essential_units_daily AS
SELECT
  date
, student_id full_student_id
, subject
, app
, SUM(is_essential) essential_units_attempted
, SUM((CASE WHEN ((is_essential = 1) AND (is_mastered = 1)) THEN 1 ELSE 0 END)) essential_units_mastered
, SUM(is_mastered) total_units_mastered_lm
FROM
  studient.khiem_v_essential_units
WHERE REGEXP_LIKE(student_id, '^[0-9]{3}-[0-9]{4}$')
GROUP BY 1, 2, 3, 4
