-- VIEW: studient.khiem_identity_bridge
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_identity_bridge AS
WITH
  dlm_identities AS (
   SELECT DISTINCT
     student_id uuid
   , LOWER(trim(BOTH FROM email)) email_norm
   , LPAD(CAST(campus_id AS VARCHAR), 3, '0') campus_id
   , (CASE WHEN REGEXP_LIKE(CAST(external_student_id AS VARCHAR), '^[0-9]+$') THEN LPAD(CAST(external_student_id AS VARCHAR), 4, '0') ELSE null END) external_id_4
   , student student_name_dlm
   FROM
     studient.daily_learning_metrics
   WHERE ((student_id IS NOT NULL) AND (external_student_id IS NOT NULL) AND (campus_id IS NOT NULL) AND REGEXP_LIKE(CAST(external_student_id AS VARCHAR), '^[0-9]+$'))
) 
, uuid_map AS (
   SELECT
     uuid
   , MAX(email_norm) email_norm
   , MAX(campus_id) campus_id
   , MAX(external_id_4) external_id_4
   , MAX(student_name_dlm) student_name
   FROM
     dlm_identities
   GROUP BY uuid
) 
, email_map AS (
   SELECT
     email_norm
   , MAX(CONCAT(campus_id, '-', external_id_4)) fullid
   , MAX(student_name_dlm) student_name
   FROM
     dlm_identities
   WHERE ((email_norm IS NOT NULL) AND (email_norm <> ''))
   GROUP BY email_norm
) 
, extid_map AS (
   SELECT
     CONCAT(campus_id, '-', external_id_4) fullid
   , external_id_4
   , campus_id
   , MAX(student_name_dlm) student_name
   FROM
     dlm_identities
   GROUP BY CONCAT(campus_id, '-', external_id_4), external_id_4, campus_id
) 
, roster_identities AS (
   SELECT DISTINCT
     fullid
   , LPAD(CAST(campusid AS VARCHAR), 3, '0') campus_id
   , id external_id_4
   , fullname student_name
   , LOWER(trim(BOTH FROM email)) email_norm
   FROM
     studient.alpha_student
   WHERE ((fullid IS NOT NULL) AND (id IS NOT NULL) AND (NOT (EXISTS (SELECT 1
FROM
  dlm_identities d
WHERE ((d.campus_id = LPAD(CAST(campusid AS VARCHAR), 3, '0')) AND (d.external_id_4 = id))
))))
) 
SELECT
  'UUID' bridge_type
, uuid
, campus_id
, external_id_4
, CONCAT(campus_id, '-', external_id_4) fullid
, student_name
, email_norm
FROM
  uuid_map
UNION ALL SELECT
  'EMAIL'
, null
, SUBSTRING(fullid, 1, 3)
, SUBSTRING(fullid, 5)
, fullid
, student_name
, email_norm
FROM
  email_map
UNION ALL SELECT
  'EXTID'
, null
, campus_id
, external_id_4
, fullid
, student_name
, null
FROM
  extid_map
UNION ALL SELECT
  'ROSTER'
, null
, campus_id
, external_id_4
, fullid
, student_name
, email_norm
FROM
  roster_identities
