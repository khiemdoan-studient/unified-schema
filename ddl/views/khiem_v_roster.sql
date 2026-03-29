-- VIEW: studient.khiem_v_roster
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_roster AS
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
FROM
  studient.alpha_student s
