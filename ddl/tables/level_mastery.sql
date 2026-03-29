-- EXTERNAL TABLE: studient.level_mastery
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.level_mastery`(
  `id` string, 
  `mastered_at` timestamp, 
  `topic_mastery_id` string, 
  `date` date, 
  `student` string, 
  `external_student_id` string, 
  `app` string, 
  `subject` string, 
  `course` string, 
  `topic` string, 
  `level` string, 
  `mastery_percentage` float, 
  `activity_units_attempted` int, 
  `activity_units_correct` int, 
  `app_reported_time_minutes` float, 
  `app_specific_data` string, 
  `url` string, 
  `third_party_level_id` string, 
  `resource_type` string, 
  `active_minutes` float, 
  `status` string)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://alphacoachbot-production-quicksight-s3-datasource/levelMastery'
TBLPROPERTIES (
  'transient_lastDdlTime'='1772770853')
