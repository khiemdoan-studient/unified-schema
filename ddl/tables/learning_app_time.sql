-- EXTERNAL TABLE: studient.learning_app_time
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.learning_app_time`(
  `student` string, 
  `student_id` string, 
  `external_student_id` string, 
  `app` string, 
  `app_id` string, 
  `subject` string, 
  `subject_id` string, 
  `date` date, 
  `start_time` timestamp, 
  `duration_minutes` float, 
  `level` string, 
  `third_party_level_id` string, 
  `url` string)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://alphacoachbot-production-quicksight-s3-datasource/learningAppTime'
TBLPROPERTIES (
  'transient_lastDdlTime'='1772770833')
