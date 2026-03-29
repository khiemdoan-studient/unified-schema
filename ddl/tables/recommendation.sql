-- EXTERNAL TABLE: studient.recommendation
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.recommendation`(
  `recommendation_id` string COMMENT 'from deserializer', 
  `student_id` string COMMENT 'from deserializer', 
  `subject_id` string COMMENT 'from deserializer', 
  `app` string COMMENT 'from deserializer', 
  `name` string COMMENT 'from deserializer', 
  `grade` string COMMENT 'from deserializer', 
  `type` string COMMENT 'from deserializer', 
  `url` string COMMENT 'from deserializer', 
  `skill_id` string COMMENT 'from deserializer', 
  `block` string COMMENT 'from deserializer', 
  `status` string COMMENT 'from deserializer', 
  `smart_score` string COMMENT 'from deserializer', 
  `created_on` string COMMENT 'from deserializer', 
  `updated_on` string COMMENT 'from deserializer', 
  `invalidated_on` string COMMENT 'from deserializer', 
  `recommendation_source` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/recommendation'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770955')
