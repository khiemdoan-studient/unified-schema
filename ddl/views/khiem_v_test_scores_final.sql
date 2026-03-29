-- VIEW: studient.khiem_v_test_scores_final
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_test_scores_final AS
WITH
  roster_lookup AS (
   SELECT
     id external_id_str
   , fullid
   , fullname
   , LOWER(trim(BOTH FROM email)) email_norm
   , LPAD(CAST(campusid AS VARCHAR), 3, '0') campus_id
   FROM
     studient.alpha_student
) 
, raw_tests AS (
   SELECT
     assignmentid test_id
   , 'Edulastic' source_system
   , TRY(CAST(DATE_PARSE(COALESCE(NULLIF(enddate, ''), NULLIF(startdate, '')), '%Y-%m-%d') AS DATE)) date
   , userid source_student_id
   , LOWER(trim(BOTH FROM username)) source_email
   , title test_name
   , subject
   , 'Edulastic Assignment' test_type
   , TRY_CAST(score AS DOUBLE) score
   , TRY_CAST(maxscore AS DOUBLE) max_score
   , TRY_CAST(NULLIF(accuracy, '') AS DOUBLE) accuracy_raw
   , status
   , TRY_CAST(minutesspent AS DOUBLE) duration_minutes
   FROM
     studient.edulastic_data
   WHERE (status = 'Graded')
UNION ALL    SELECT
     CAST(id AS VARCHAR) test_id
   , 'CoachBot' source_system
   , test_date date
   , external_student_id source_student_id
   , (CASE WHEN (STRPOS(external_student_id, '@') > 0) THEN LOWER(trim(BOTH FROM external_student_id)) ELSE null END) source_email
   , test_name
   , subject
   , test_type
   , CAST(score AS DOUBLE) score
   , null max_score
   , accuracy accuracy_raw
   , 'Graded' status
   , test_duration_minutes duration_minutes
   FROM
     studient.test_scores
   WHERE (test_date IS NOT NULL)
UNION ALL    SELECT
     CONCAT('NWEA-', full_student_id, '-', test_window) test_id
   , 'NWEA' source_system
   , test_date date
   , full_student_id source_student_id
   , null source_email
   , CONCAT('MAP ', subject_lower, ' - ', test_window) test_name
   , subject_lower subject
   , 'MAP' test_type
   , CAST(rit_score AS DOUBLE) score
   , null max_score
   , null accuracy_raw
   , 'Graded' status
   , null duration_minutes
   FROM
     (
      SELECT
        full_student_id
      , subject_lower
      , winter_rit rit_score
      , DATE '2026-01-15' test_date
      , 'Winter 2025-2026' test_window
      FROM
        studient.khiem_v_nwea_comprehensive
      WHERE (winter_rit IS NOT NULL)
UNION ALL       SELECT
        full_student_id
      , subject_lower
      , fall_rit
      , DATE '2025-09-15' test_date
      , 'Fall 2025-2026'
      FROM
        studient.khiem_v_nwea_comprehensive
      WHERE (fall_rit IS NOT NULL)
UNION ALL       SELECT
        full_student_id
      , subject_lower
      , spring_rit
      , DATE '2026-05-15' test_date
      , 'Spring 2025-2026'
      FROM
        studient.khiem_v_nwea_comprehensive
      WHERE (spring_rit IS NOT NULL)
   )  nwea_tests
) 
, joined_tests AS (
   SELECT
     t.date
   , COALESCE(r_fullid.fullid, r_id.fullid, r_email.fullid, ib_extid.fullid, ib_email.fullid, ib_roster.fullid, t.source_student_id) student_id
   , COALESCE(r_fullid.fullname, r_id.fullname, r_email.fullname, ib_extid.student_name, ib_email.student_name, ib_roster.student_name, 'Unknown Student') student_name
   , t.source_system
   , t.test_name
   , t.subject
   , t.test_type
   , t.score
   , t.max_score
   , (CASE WHEN (t.accuracy_raw <= 1) THEN (t.accuracy_raw * 100) ELSE t.accuracy_raw END) accuracy_pct
   , (CASE WHEN (t.test_type = 'MAP') THEN (CASE WHEN (t.score >= 50) THEN 'On Track' ELSE 'Off Track' END) WHEN ((CASE WHEN (t.accuracy_raw <= 1) THEN (t.accuracy_raw * 100) ELSE t.accuracy_raw END) >= 8.95E1) THEN 'Pass' ELSE 'Fail' END) pass_fail
   , t.test_id
   , t.duration_minutes
   , ROW_NUMBER() OVER (PARTITION BY COALESCE(r_fullid.fullid, r_id.fullid, r_email.fullid, ib_extid.fullid, ib_email.fullid, ib_roster.fullid, t.source_student_id), t.date, RTRIM(t.test_name, '.'), t.source_system, ROUND((CASE WHEN (t.accuracy_raw <= 1) THEN (t.accuracy_raw * 100) ELSE t.accuracy_raw END), 4) ORDER BY t.test_id ASC) dedup_rn
   FROM
     ((((((raw_tests t
   LEFT JOIN roster_lookup r_fullid ON (t.source_student_id = r_fullid.fullid))
   LEFT JOIN roster_lookup r_id ON (REGEXP_LIKE(t.source_student_id, '^[0-9]{4}$') AND (t.source_student_id = r_id.external_id_str)))
   LEFT JOIN roster_lookup r_email ON (COALESCE(t.source_email, LOWER(trim(BOTH FROM t.source_student_id))) = r_email.email_norm))
   LEFT JOIN studient.khiem_identity_bridge ib_extid ON ((ib_extid.bridge_type = 'EXTID') AND REGEXP_LIKE(t.source_student_id, '^[0-9]{4}$') AND (LPAD(t.source_student_id, 4, '0') = ib_extid.external_id_4)))
   LEFT JOIN studient.khiem_identity_bridge ib_email ON ((ib_email.bridge_type = 'EMAIL') AND (COALESCE(t.source_email, LOWER(trim(BOTH FROM t.source_student_id))) = ib_email.email_norm)))
   LEFT JOIN studient.khiem_identity_bridge ib_roster ON ((ib_roster.bridge_type = 'ROSTER') AND (t.source_student_id = ib_roster.fullid)))
   WHERE (t.date >= DATE '2025-01-01')
) 
SELECT
  date
, student_id
, student_name
, source_system
, test_name
, subject
, test_type
, score
, max_score
, accuracy_pct
, pass_fail
, test_id
, duration_minutes
FROM
  joined_tests
WHERE (dedup_rn = 1)
