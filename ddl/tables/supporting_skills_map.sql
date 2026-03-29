-- EXTERNAL TABLE: studient.supporting_skills_map
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.supporting_skills_map`(
  `id` string COMMENT 'from deserializer', 
  `essential_skill_id` string COMMENT 'from deserializer', 
  `essential_skill_code` string COMMENT 'from deserializer', 
  `essential_skill_name` string COMMENT 'from deserializer', 
  `essential_plan_grade` string COMMENT 'from deserializer', 
  `essential_subject` string COMMENT 'from deserializer', 
  `essential_app` string COMMENT 'from deserializer', 
  `supporting_skill_id` string COMMENT 'from deserializer', 
  `supporting_skill_code` string COMMENT 'from deserializer', 
  `supporting_skill_name` string COMMENT 'from deserializer', 
  `added_by` string COMMENT 'from deserializer', 
  `invalidated_on` string COMMENT 'from deserializer', 
  `invalidated_by` string COMMENT 'from deserializer', 
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/supporting_skills_map'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772771036')
