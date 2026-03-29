-- EXTERNAL TABLE: studient.bracketing_assignments
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.bracketing_assignments`(
  `id` string COMMENT 'from deserializer', 
  `full_student_id` string COMMENT 'from deserializer', 
  `campus_id` string COMMENT 'from deserializer', 
  `student_id` string COMMENT 'from deserializer', 
  `full_name` string COMMENT 'from deserializer', 
  `level` string COMMENT 'from deserializer', 
  `student_alpha_email` string COMMENT 'from deserializer', 
  `age_grade` string COMMENT 'from deserializer', 
  `assignment_id` string COMMENT 'from deserializer', 
  `class_id` string COMMENT 'from deserializer', 
  `test_key` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `grade` string COMMENT 'from deserializer', 
  `assigned_on` string COMMENT 'from deserializer', 
  `onboarding_status` string COMMENT 'from deserializer', 
  `knowledge_gaps` string COMMENT 'from deserializer', 
  `notes` string COMMENT 'from deserializer', 
  `created_on` string COMMENT 'from deserializer', 
  `updated_on` string COMMENT 'from deserializer', 
  `invalidated_on` string COMMENT 'from deserializer')
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.serde2.OpenCSVSerde' 
WITH SERDEPROPERTIES ( 
  'escapeChar'='\\', 
  'quoteChar'='\"', 
  'separatorChar'=',') 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/bracketing_assignments'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770632')
