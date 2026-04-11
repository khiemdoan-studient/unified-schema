-- Migration 001: Add externalstudentid to alpha_student and downstream views
-- Run in: Prod-Academics-Studient Athena console (account 8821-1239-7037)
-- Database: studient
-- Date: 2026-04-10
--
-- IMPORTANT: The underlying S3 data at
--   s3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/student
-- must already contain the new columns (is_test, admission_date, externalstudentid)
-- in the pipe-delimited file. The RAPIDAPI dash-data.alpha_student confirms
-- the upstream data feed includes these columns.
--
-- Execution order matters: table first, then views in dependency order.
-- ═══════════════════════════════════════════════════════════════════════════


-- ── STEP 1: Recreate alpha_student with 3 new columns ──────────────────────
-- The table is EXTERNAL (points to S3), so DROP only removes the metadata.
-- No data is deleted.

DROP TABLE IF EXISTS studient.alpha_student;

CREATE EXTERNAL TABLE `studient.alpha_student`(
  `fullid` string,
  `campusid` bigint,
  `id` string,
  `firstname` string,
  `preferredname` string,
  `lastname` string,
  `dateofbirth` string,
  `gender` string,
  `alphalevellong` string,
  `gradelevel` string,
  `email` string,
  `campus` string,
  `group` string,
  `withdrawdate` string,
  `portfoliourl` string,
  `fullname` string,
  `alphalevelshort` string,
  `alphalevel` double,
  `advisor` string,
  `advisoremail` string,
  `grade` string,
  `language` string,
  `map_accommodations` string,
  `admissionstatus` string,
  `is_test` string,
  `admission_date` string,
  `externalstudentid` string)
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY '|'
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/student'
TBLPROPERTIES (
  'skip.header.line.count'='1');


-- ── STEP 2: Verify new columns are populated ────────────────────────────────

SELECT fullid, admissionstatus, is_test, admission_date, externalstudentid
FROM studient.alpha_student
WHERE campus = 'JRHS - Ridgeland Secondary Academy of Excellence'
LIMIT 5;

-- Expected: externalstudentid should show values like '5574302705'
-- If externalstudentid is NULL for all rows, the S3 data file may not have
-- the new columns yet. In that case, see the sync instructions below.


-- ── STEP 3: Update khiem_v_roster ───────────────────────────────────────────

CREATE OR REPLACE VIEW studient.khiem_v_roster AS
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
FROM
  studient.alpha_student s;


-- ── STEP 4: Verify roster has the new column ────────────────────────────────

SELECT full_student_id, student_name, campus_name, externalstudentid
FROM studient.khiem_v_roster
WHERE campus_id = '087'
LIMIT 5;


-- ═══════════════════════════════════════════════════════════════════════════
-- STEPS 5-6: Update khiem_v_lesson_unified and khiem_v_weekly_dashboard
--
-- These views are too large for inline SQL here. Use the updated DDL files:
--   ddl/views/khiem_v_lesson_unified.sql
--   ddl/views/khiem_v_weekly_dashboard.sql
--
-- Run them as CREATE OR REPLACE VIEW in this order:
--   1. khiem_v_lesson_unified   (depends on khiem_v_roster)
--   2. khiem_v_weekly_dashboard (depends on khiem_v_roster + khiem_v_lesson_unified)
--
-- For each file, change "CREATE VIEW" to "CREATE OR REPLACE VIEW" before running.
-- ═══════════════════════════════════════════════════════════════════════════


-- ── STEP 7: Final verification ──────────────────────────────────────────────

-- Check lesson_unified has the column
SELECT student_id, student_name, externalstudentid, activity_date, row_type
FROM studient.khiem_v_lesson_unified
WHERE campus_id = '087'
LIMIT 5;

-- Check weekly_dashboard has the column
SELECT student_id, student_name, externalstudentid, week_start
FROM studient.khiem_v_weekly_dashboard
WHERE campus_id = '087'
LIMIT 5;
