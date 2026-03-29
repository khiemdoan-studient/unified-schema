-- EXTERNAL TABLE: studient.missing_minutes_override
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.missing_minutes_override`(
  `id` int, 
  `date` date, 
  `student` string, 
  `external_student_id` string, 
  `app` string, 
  `subject` string, 
  `minutes` float, 
  `explanation` string)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY ',' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/missing_minutes_override'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772770893')
