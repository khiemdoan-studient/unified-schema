-- EXTERNAL TABLE: studient.twohr_overrides
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.twohr_overrides`(
  `id` string COMMENT 'from deserializer', 
  `learning_session_date` string COMMENT 'from deserializer', 
  `campus_id` string COMMENT 'from deserializer', 
  `student_id` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `explanation` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/2hr-overrides'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772771077')
