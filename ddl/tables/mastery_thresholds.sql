-- EXTERNAL TABLE: studient.mastery_thresholds
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.mastery_thresholds`(
  `id` string COMMENT 'from deserializer', 
  `campus_id` string COMMENT 'from deserializer', 
  `app` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `grade` string COMMENT 'from deserializer', 
  `target_mastery_units` string COMMENT 'from deserializer', 
  `business_key` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/mastery_thresholds'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770874')
