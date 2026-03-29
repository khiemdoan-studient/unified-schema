-- EXTERNAL TABLE: studient.skill_plan
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.skill_plan`(
  `id` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `app` string COMMENT 'from deserializer', 
  `skill_name` string COMMENT 'from deserializer', 
  `type` string COMMENT 'from deserializer', 
  `order` string COMMENT 'from deserializer', 
  `keep` string COMMENT 'from deserializer', 
  `skill_id` string COMMENT 'from deserializer', 
  `skill_code` string COMMENT 'from deserializer', 
  `plan_grade` string COMMENT 'from deserializer', 
  `plan_grade_level` string COMMENT 'from deserializer', 
  `plan_grade_rank` string COMMENT 'from deserializer', 
  `source` string COMMENT 'from deserializer', 
  `revision` string COMMENT 'from deserializer', 
  `notes` string COMMENT 'from deserializer', 
  `invalidated_on` string COMMENT 'from deserializer', 
  `created_on` string COMMENT 'from deserializer', 
  `updated_on` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/skill_plan'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770975')
