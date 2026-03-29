-- EXTERNAL TABLE: studient.app_chronicle
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.app_chronicle`(
  `studentid` string COMMENT 'from deserializer', 
  `name` string COMMENT 'from deserializer', 
  `lvl` string COMMENT 'from deserializer', 
  `username` string COMMENT 'from deserializer', 
  `password` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `coursename` string COMMENT 'from deserializer', 
  `app` string COMMENT 'from deserializer', 
  `start` string COMMENT 'from deserializer', 
  `end` string COMMENT 'from deserializer', 
  `reasonforplacement` string COMMENT 'from deserializer', 
  `notes` string COMMENT 'from deserializer', 
  `email` string COMMENT 'from deserializer', 
  `uuid` string COMMENT 'from deserializer', 
  `roasteredby` string COMMENT 'from deserializer', 
  `metadata` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/app-chronicle'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770592')
