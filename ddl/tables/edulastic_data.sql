-- EXTERNAL TABLE: studient.edulastic_data
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.edulastic_data`(
  `id` string COMMENT 'from deserializer', 
  `assignmentid` string COMMENT 'from deserializer', 
  `userid` string COMMENT 'from deserializer', 
  `status` string COMMENT 'from deserializer', 
  `startdate` string COMMENT 'from deserializer', 
  `enddate` string COMMENT 'from deserializer', 
  `maxscore` string COMMENT 'from deserializer', 
  `score` string COMMENT 'from deserializer', 
  `accuracy` string COMMENT 'from deserializer', 
  `title` string COMMENT 'from deserializer', 
  `username` string COMMENT 'from deserializer', 
  `firstname` string COMMENT 'from deserializer', 
  `lastname` string COMMENT 'from deserializer', 
  `name` string COMMENT 'from deserializer', 
  `minutesspent` string COMMENT 'from deserializer', 
  `grade` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `created_at` string COMMENT 'from deserializer', 
  `updated_at` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/edulastic_data'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770673')
