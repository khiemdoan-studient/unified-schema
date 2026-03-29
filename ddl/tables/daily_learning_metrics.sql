-- EXTERNAL TABLE: studient.daily_learning_metrics
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.daily_learning_metrics`(
  `date` date, 
  `student` string, 
  `email` string, 
  `coach` string, 
  `school` string, 
  `team` string, 
  `app` string, 
  `app_id` string, 
  `course` string, 
  `course_id` string, 
  `subject` string, 
  `active_minutes` float, 
  `active_minutes_2x_threshold_low` float, 
  `correct_questions_hr` float, 
  `correct_questions` int, 
  `correct_questions_hr_2x_threshold_low` float, 
  `correct_questions_hr_2x_threshold_high` float, 
  `correct_questions_percentage` int, 
  `total_questions_attempted` int, 
  `levels_mastered` int, 
  `total_course_levels` int, 
  `total_mastered_levels` int, 
  `learning_level` string, 
  `external_student_id` string, 
  `course_levels_mastered_hr_mean` float, 
  `learning_unit_passed` string, 
  `learning_2x_minutes` int, 
  `student_id` string, 
  `antipattern_finding_names` string, 
  `antipattern_count` int, 
  `max_time_wasted_percentage` float, 
  `max_correct_questions_impacted_percentage` float, 
  `max_correct_questions_impacted` int, 
  `most_significant_antipattern_finding_id` string, 
  `most_significant_antipattern_finding_name` string, 
  `campus_id` string)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://alphacoachbot-production-quicksight-s3-datasource/dailyMetricsReport'
TBLPROPERTIES (
  'transient_lastDdlTime'='1772770653')
