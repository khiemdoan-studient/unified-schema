-- EXTERNAL TABLE: studient.test_scores
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.test_scores`(
  `id` string, 
  `student` string, 
  `student_id` string, 
  `external_student_id` string, 
  `subject` string, 
  `subject_id` string, 
  `season` string, 
  `grade` string, 
  `test_name` string, 
  `test_duration_minutes` float, 
  `test_type` string, 
  `score` int, 
  `standard_error` float, 
  `percentile` int, 
  `questions_answered` int, 
  `accuracy` float, 
  `test_date` date, 
  `test_url` string, 
  `app` string, 
  `third_party_test_id` string, 
  `result_id` string)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://alphacoachbot-production-quicksight-s3-datasource/testScores'
TBLPROPERTIES (
  'transient_lastDdlTime'='1772771056')
