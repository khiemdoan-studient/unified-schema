-- EXTERNAL TABLE: studient.edulastic_mastered_skills
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.edulastic_mastered_skills`(
  `id` string COMMENT 'from deserializer', 
  `date` string COMMENT 'from deserializer', 
  `external_student_id` string COMMENT 'from deserializer', 
  `app` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `third_party_level_id` string COMMENT 'from deserializer', 
  `thirdpartylevelcode` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/edulastic_mastered_skills'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770693')

DONE
