-- VIEW: studient.khiem_v_essential_skill_counts
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_essential_skill_counts AS
SELECT
  app
, subject
, plan_grade
, COUNT(DISTINCT skill_id) total_essential_skills
FROM
  studient.skill_plan
WHERE ((type = 'essential') AND (source IN ('Academics', 'Academics - In Transition')) AND (COALESCE(invalidated_on, '') = ''))
GROUP BY app, subject, plan_grade
