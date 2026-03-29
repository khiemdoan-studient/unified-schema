-- VIEW: studient.khiem_v_full_skill_plan
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_full_skill_plan AS
WITH
  grade_rank_mapping AS (
   SELECT *
   FROM
     (
 VALUES 
        ROW ('Pre-K', 'PK', -1)
      , ROW ('Kindergarten', 'K', 0)
      , ROW ('First grade', '01', 1)
      , ROW ('Second grade', '02', 2)
      , ROW ('Third grade', '03', 3)
      , ROW ('Fourth grade', '04', 4)
      , ROW ('Fifth grade', '05', 5)
      , ROW ('Sixth grade', '06', 6)
      , ROW ('Seventh grade', '07', 7)
      , ROW ('Eighth grade', '08', 8)
      , ROW ('Ninth grade', '09', 9)
      , ROW ('Tenth grade', '10', 10)
      , ROW ('Eleventh grade', '11', 11)
      , ROW ('Twelfth grade', '12', 12)
   )  t (grade, grade_level, grade_rank)
) 
, essential_skills AS (
   SELECT
     sp1.subject
   , sp1.app
   , sp1.type
   , sp1.skill_name
   , sp1.skill_id
   , sp1.skill_code
   , sp1.plan_grade
   , sp1.plan_grade course
   , sp1.plan_grade_level
   , CAST(sp1.plan_grade_rank AS INTEGER) plan_grade_rank
   , CAST(sp1."order" AS BIGINT) "order"
   , sp1.source
   FROM
     (studient.skill_plan sp1
   LEFT JOIN studient.skill_plan sp2 ON ((sp1.app = sp2.app) AND (sp1.subject = sp2.subject) AND ((sp1.skill_id = sp2.skill_id) OR (sp1.skill_code = sp2.skill_code)) AND (sp2.source = 'Academics') AND (sp2.type = 'essential') AND (COALESCE(sp2.invalidated_on, '') = '')))
   WHERE ((sp1.type = 'essential') AND (sp1.source IN ('Academics', 'Academics - In Transition')) AND (COALESCE(sp1.invalidated_on, '') = '') AND ((sp1.source = 'Academics') OR (sp2.skill_id IS NULL)))
) 
SELECT *
FROM
  essential_skills
UNION ALL SELECT DISTINCT
  ssm.essential_subject subject
, ssm.essential_app app
, 'supporting' type
, ssm.supporting_skill_name skill_name
, ssm.supporting_skill_id skill_id
, ssm.supporting_skill_code skill_code
, asi.grade plan_grade
, asi.grade course
, grm.grade_level plan_grade_level
, CAST(grm.grade_rank AS INTEGER) plan_grade_rank
, ROW_NUMBER() OVER (PARTITION BY ssm.essential_subject, ssm.essential_app, asi.grade, grm.grade_level, grm.grade_rank ORDER BY ssm.id ASC) "order"
, sp.source
FROM
  ((((studient.supporting_skills_map ssm
INNER JOIN essential_skills sp ON ((sp.subject = ssm.essential_subject) AND (sp.app = ssm.essential_app) AND (sp.plan_grade = ssm.essential_plan_grade) AND (sp.skill_id = ssm.essential_skill_id)))
INNER JOIN studient.all_skills_ixl asi ON ((ssm.supporting_skill_id = CAST(asi.skill_id AS VARCHAR)) AND (ssm.supporting_skill_code = asi.permacode)))
INNER JOIN grade_rank_mapping grm ON (grm.grade = asi.grade))
LEFT JOIN essential_skills dupes ON ((dupes.subject = ssm.essential_subject) AND (dupes.app = ssm.essential_app) AND (dupes.skill_id = ssm.supporting_skill_id)))
WHERE ((COALESCE(ssm.invalidated_on, '') = '') AND (dupes.skill_id IS NULL))
