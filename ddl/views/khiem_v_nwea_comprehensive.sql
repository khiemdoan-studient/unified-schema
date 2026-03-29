-- VIEW: studient.khiem_v_nwea_comprehensive
-- Extracted from AWS Athena on 2026-03-29

CREATE VIEW studient.khiem_v_nwea_comprehensive AS
SELECT
  studentid full_student_id
, LOWER(subject) subject_lower
, MAX((CASE WHEN (termname LIKE 'Fall %') THEN testritscore END)) fall_rit
, MAX((CASE WHEN (termname LIKE 'Winter %') THEN testritscore END)) winter_rit
, MAX((CASE WHEN (termname LIKE 'Spring %') THEN testritscore END)) spring_rit
, MAX((CASE WHEN (termname LIKE 'Fall %') THEN testpercentile END)) fall_cgp
, MAX((CASE WHEN (termname LIKE 'Winter %') THEN testpercentile END)) winter_cgp
, MAX((CASE WHEN (termname LIKE 'Spring %') THEN testpercentile END)) spring_cgp
, MAX((CASE WHEN (termname LIKE 'Winter %') THEN falltowinterprojectedgrowth END)) f2w_projected_growth
, MAX((CASE WHEN (termname LIKE 'Winter %') THEN falltowinterobservedgrowth END)) f2w_observed_growth
FROM
  studient.nwea_reports
GROUP BY studentid, LOWER(subject)
