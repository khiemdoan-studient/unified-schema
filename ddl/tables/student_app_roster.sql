-- EXTERNAL TABLE: studient.student_app_roster
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.student_app_roster`(
  `id` string COMMENT 'from deserializer', 
  `student_id` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `recommended_app` string COMMENT 'from deserializer', 
  `recommended_course` string COMMENT 'from deserializer', 
  `recommended_course_level` string COMMENT 'from deserializer', 
  `reason_for_placement` string COMMENT 'from deserializer', 
  `last_updated_by` string COMMENT 'from deserializer', 
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/student_app_roster'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770995')
