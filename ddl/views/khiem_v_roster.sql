-- VIEW: studient.khiem_v_roster
-- Extracted from AWS Athena on 2026-03-29
-- Updated 2026-04-06: Added dedup (ROW_NUMBER by fullid, prefer group-populated row)
--                      and WHERE admissionstatus = 'Enrolled' filter.
-- Updated 2026-04-08: Fixed ghost students. 24 students had most-recent status
--                      "Former Student" or "Mid-Year Unenrollment" but older "Enrolled"
--                      rows. The v1.1.0 WHERE filter ran BEFORE dedup, so the Enrolled
--                      rows passed and the student appeared in the roster.
--                      Fix: exclude any fullid that has a non-Enrolled row, then dedup
--                      among remaining Enrolled-only students. This is safe because
--                      0 re-enrolled students exist in the data (no student has both
--                      a current Enrolled row AND a historical Former Student row).

CREATE OR REPLACE VIEW studient.khiem_v_roster AS
WITH unenrolled AS (
  -- Students with ANY non-Enrolled row are definitively not enrolled
  SELECT DISTINCT fullid
  FROM studient.alpha_student
  WHERE admissionstatus IN ('Former Student', 'Mid-Year Unenrollment')
),
ranked AS (
  SELECT
    s.fullid full_student_id
  , LPAD(CAST(s.campusid AS VARCHAR), 3, '0') campus_id
  , s.id external_student_id
  , s.fullname student_name
  , s.gradelevel grade
  , s.alphalevelshort age_grade
  , s.alphalevellong level
  , s.advisor teacher_name
  , s.campus campus_name
  , s.admissionstatus status
  , s.email student_email
  , s.advisoremail teacher_email
  , s.externalstudentid
  , ROW_NUMBER() OVER (
      PARTITION BY s.fullid
      ORDER BY
        CASE WHEN s."group" IS NOT NULL AND s."group" <> '' THEN 0 ELSE 1 END ASC,
        s.fullid ASC
    ) rn
  FROM studient.alpha_student s
  WHERE s.admissionstatus = 'Enrolled'
    AND s.fullid NOT IN (SELECT fullid FROM unenrolled)
)
SELECT
  full_student_id, campus_id, external_student_id, student_name,
  grade, age_grade, level, teacher_name, campus_name, status,
  student_email, teacher_email, externalstudentid
FROM ranked
WHERE rn = 1
