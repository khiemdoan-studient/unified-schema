-- VIEW: studient.khiem_v_essential_units
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_essential_units AS
SELECT
  CAST(lm.date AS DATE) date
, COALESCE(r.full_student_id, ib_extid.fullid, lm.external_student_id) student_id
, lm.app
, lm.subject
, lm.course
, lm.level lesson_name
, lm.topic
, lm.resource_type
, (CASE WHEN (lm.resource_type = 'essential') THEN 1 ELSE 0 END) is_essential
, (CASE WHEN (lm.status = 'completed') THEN 1 ELSE 0 END) is_mastered
FROM
  ((studient.level_mastery lm
LEFT JOIN studient.khiem_v_roster r ON (lm.external_student_id = r.external_student_id))
LEFT JOIN studient.khiem_identity_bridge ib_extid ON ((ib_extid.bridge_type = 'EXTID') AND REGEXP_LIKE(lm.external_student_id, '^[0-9]+$') AND (LPAD(lm.external_student_id, 4, '0') = ib_extid.external_id_4)))
WHERE (lm.date IS NOT NULL)
