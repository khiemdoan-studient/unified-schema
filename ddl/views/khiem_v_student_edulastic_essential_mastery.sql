-- VIEW: studient.khiem_v_student_edulastic_essential_mastery
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_student_edulastic_essential_mastery AS
SELECT
  ems.external_student_id
, ems.date
, ems.subject
, ems.app
, ems.third_party_level_id
, ems.thirdpartylevelcode skill_code
, sp.plan_grade
, sp.type
, sp.skill_id
, (CASE WHEN (sp.type = 'essential') THEN 1 ELSE 0 END) is_essential_mastered
FROM
  (studient.edulastic_mastered_skills ems
INNER JOIN studient.skill_plan sp ON ((ems.thirdpartylevelcode = sp.skill_code) AND (LOWER(ems.app) = LOWER(sp.app))))
WHERE ((sp.type = 'essential') AND (sp.source IN ('Academics', 'Academics - In Transition')) AND (COALESCE(sp.invalidated_on, '') = ''))
