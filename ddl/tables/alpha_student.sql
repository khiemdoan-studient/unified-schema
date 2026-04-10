-- EXTERNAL TABLE: studient.alpha_student
-- Extracted from AWS Athena on 2026-03-29
-- Updated 2026-04-10: Added is_test, admission_date, externalstudentid
-- (columns present in upstream dash-data.alpha_student on RAPIDAPI account)

CREATE EXTERNAL TABLE `studient.alpha_student`(
  `fullid` string,
  `campusid` bigint,
  `id` string,
  `firstname` string,
  `preferredname` string,
  `lastname` string,
  `dateofbirth` string,
  `gender` string,
  `alphalevellong` string,
  `gradelevel` string,
  `email` string,
  `campus` string,
  `group` string,
  `withdrawdate` string,
  `portfoliourl` string,
  `fullname` string,
  `alphalevelshort` string,
  `alphalevel` double,
  `advisor` string,
  `advisoremail` string,
  `grade` string,
  `language` string,
  `map_accommodations` string,
  `admissionstatus` string,
  `is_test` string,
  `admission_date` string,
  `externalstudentid` string)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '|' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://alpha-backend-prod-progressrecordstore-1n0x2ke8vjgjr/student'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1772768436')
