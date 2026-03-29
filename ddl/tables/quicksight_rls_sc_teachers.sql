-- EXTERNAL TABLE: studient.quicksight_rls_sc_teachers
-- Extracted from AWS Athena on 2026-03-29

CREATE EXTERNAL TABLE `studient.quicksight_rls_sc_teachers`(
  `username` string, 
  `teacher_email` string, 
  `school_abbrev` string, 
  `campus_id` string)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://prod-academics-studient-athena-results/Unsaved/2026/02/28/tables/066ed2c2-723f-4e1f-bcb8-f5fbd67e1e91'
TBLPROPERTIES (
  'auto.purge'='false', 
  'has_encrypted_data'='false', 
  'numFiles'='-1', 
  'parquet.compression'='GZIP', 
  'totalSize'='-1', 
  'transactional'='false', 
  'transient_lastDdlTime'='1772770934', 
  'trino_query_id'='20260228_061556_00061_a6xmd', 
  'trino_version'='0.215-24526-g02c3358')
