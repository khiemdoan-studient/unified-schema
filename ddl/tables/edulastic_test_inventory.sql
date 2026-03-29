-- EXTERNAL TABLE: studient.edulastic_test_inventory
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.edulastic_test_inventory`(
  `id` string COMMENT 'from deserializer', 
  `title` string COMMENT 'from deserializer', 
  `grade` string COMMENT 'from deserializer', 
  `subject` string COMMENT 'from deserializer', 
  `legacy` string COMMENT 'from deserializer')
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
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/edulastic_test_inventory'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770712')
