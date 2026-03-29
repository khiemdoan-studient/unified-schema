-- VIEW: studient.khiem_v_student_ixl_essential_mastery
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_student_ixl_essential_mastery AS
SELECT
  ilm.full_student_id
, ilm.date
, ilm.subject
, ilm.app
, ilm.skill_id
, ilm.skill_code
, sp.plan_grade
, sp.type
, (CASE WHEN (sp.type = 'essential') THEN 1 ELSE 0 END) is_essential_mastered
FROM
  (studient.ixl_level_mastery ilm
INNER JOIN studient.skill_plan sp ON ((ilm.skill_id = sp.skill_id) AND (LOWER(ilm.app) = LOWER(sp.app))))
WHERE ((sp.type = 'essential') AND (sp.source IN ('Academics', 'Academics - In Transition')) AND (COALESCE(sp.invalidated_on, '') = ''))
