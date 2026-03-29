-- VIEW: studient.khiem_v_rls_teacher_students
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_rls_teacher_students AS
SELECT DISTINCT
  r.teacher_email
, r.teacher_name
, r.full_student_id student_id
, r.student_name student
, r.campus_id
, r.campus_name school
FROM
  studient.khiem_v_roster r
WHERE ((r.teacher_email IS NOT NULL) AND (r.teacher_email <> ''))
