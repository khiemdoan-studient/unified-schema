-- VIEW: studient.khiem_v_course_essential_totals
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_course_essential_totals AS
SELECT
  LOWER(subject) subject
, LOWER(app) app
, course
, COUNT(DISTINCT skill_code) total_course_essential_levels
FROM
  studient.khiem_v_full_skill_plan
WHERE (type = 'essential')
GROUP BY 1, 2, 3
