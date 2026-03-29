-- VIEW: studient.khiem_v_essential_skills
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_essential_skills AS
SELECT DISTINCT
  LOWER(app) app
, LOWER(subject) subject
, skill_code
, skill_id
, plan_grade
, plan_grade_level
FROM
  studient.ext_515_skill_plan
WHERE ((type = 'essential') AND (source IN ('Academics', 'Academics - In Transition')))
