-- VIEW: studient.khiem_v_lesson_unified
-- Extracted from AWS Athena on 2026-03-29

CREATE OR REPLACE VIEW studient.khiem_v_lesson_unified AS
WITH
  target_campuses AS (
   SELECT campus_id
   FROM
     (
 VALUES 
        '056'
      , '066'
      , '033'
      , '068'
      , '079'
      , '082'
      , '083'
      , '084'
      , '085'
      , '086'
      , '087'
      , '088'
   )  t (campus_id)
)
, alpha_student_dedup AS (
   -- Dedup alpha_student: 1 row per student, prefer row with group populated (most recent assignment)
   SELECT fullid, student_group, advisoremail
   FROM (
     SELECT fullid, "group" AS student_group, advisoremail,
       ROW_NUMBER() OVER (PARTITION BY fullid
         ORDER BY CASE WHEN "group" IS NOT NULL AND "group" <> '' THEN 0 ELSE 1 END ASC
       ) rn
     FROM studient.alpha_student
     WHERE admissionstatus = 'Enrolled'
   )
   WHERE rn = 1
)
, first_real_placement AS (
   -- First ONBOARDED/ROSTERED entry where KGs were assigned (not initial placement).
   -- Notes containing "Assigning" indicate real placement with learning gaps.
   -- Initial placement notes say "First X test" or "Reassigning grade lowest grade".
   -- Passes on or after this date count as grade levels mastered.
   SELECT full_student_id, LOWER(trim(BOTH FROM subject)) AS subject,
     MIN(TRY(CAST(from_iso8601_timestamp(assigned_on) AS DATE))) AS first_placed
   FROM studient.bracketing_assignments
   WHERE onboarding_status IN ('ONBOARDED', 'ROSTERED')
     AND notes LIKE '%Assigning%KG%'
     AND assigned_on IS NOT NULL
   GROUP BY 1, 2
)
, ixl_grade_lookup AS (
   SELECT
     app
   , subject
   , total_essential_skills
   , (CASE plan_grade WHEN 'Pre-K' THEN -1 WHEN 'Kindergarten' THEN 0 WHEN 'First grade' THEN 1 WHEN 'Second grade' THEN 2 WHEN 'Third grade' THEN 3 WHEN 'Fourth grade' THEN 4 WHEN 'Fifth grade' THEN 5 WHEN 'Sixth grade' THEN 6 WHEN 'Seventh grade' THEN 7 WHEN 'Eighth grade' THEN 8 WHEN 'Ninth grade' THEN 9 WHEN 'Tenth grade' THEN 10 WHEN 'Eleventh grade' THEN 11 WHEN 'Twelfth grade' THEN 12 ELSE null END) numeric_grade
   FROM
     studient.khiem_v_essential_skill_counts
   WHERE (app = 'IXL')
) 
, lesson_base AS (
   SELECT
     lm.id lesson_id
   , CAST(lm.date AS DATE) lesson_date
   , lm.student student_name_source
   , lm.external_student_id
   , lm.app
   , CONCAT(UPPER(SUBSTR(trim(BOTH FROM lm.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM lm.subject), 2))) subject_display
   , (CASE WHEN (LOWER(trim(BOTH FROM lm.subject)) = 'reading') THEN 'Reading' WHEN (LOWER(trim(BOTH FROM lm.subject)) = 'language') THEN 'Language' WHEN (LOWER(trim(BOTH FROM lm.subject)) = 'math') THEN 'Math' ELSE CONCAT(UPPER(SUBSTR(trim(BOTH FROM lm.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM lm.subject), 2))) END) subject
   , lm.course
   , lm.topic
   , lm.level lesson_name
   , TRY_CAST(lm.mastery_percentage AS DOUBLE) mastery_percentage
   , COALESCE(TRY_CAST(lm.activity_units_attempted AS INTEGER), 0) activity_units_attempted
   , COALESCE(TRY_CAST(lm.activity_units_correct AS INTEGER), 0) activity_units_correct
   , TRY_CAST(lm.app_reported_time_minutes AS DOUBLE) app_reported_time_minutes
   , COALESCE(TRY_CAST(lm.active_minutes AS DOUBLE), 0) active_minutes
   , lm.url lesson_url
   , lm.resource_type
   , lm.status
   , (CASE WHEN (LOWER(COALESCE(lm.resource_type, '')) = 'essential') THEN 1 ELSE 0 END) is_essential
   , (CASE
        WHEN (LOWER(COALESCE(lm.status, '')) IN ('completed', 'mastered', 'passed')) THEN 1
        -- v3.28.0 (2026-04-23): Accuracy-based fallback for apps that don't populate `status`.
        -- Lalilo, Duolingo, AlphaWrite, etc. never set status='completed' even when the student
        -- mastered the activity. Without this fallback ~17,600 student-lesson rows/month are
        -- silently dropped. Rule: if status is null/empty AND >=3 questions attempted AND >=80%
        -- correct → count as mastered. The 3-question floor prevents 1/1 or 2/2 lucky guesses.
        -- Audit: SELECT app, COUNT(*) ... FROM level_mastery WHERE status IS NULL GROUP BY app.
        WHEN (lm.status IS NULL OR lm.status = '')
             AND COALESCE(TRY_CAST(lm.activity_units_attempted AS INTEGER), 0) >= 3
             AND CAST(COALESCE(TRY_CAST(lm.activity_units_correct AS INTEGER), 0) AS DOUBLE)
                 / NULLIF(COALESCE(TRY_CAST(lm.activity_units_attempted AS INTEGER), 0), 0) >= 0.80
        THEN 1
        ELSE 0
     END) is_mastered
   , ROW_NUMBER() OVER (PARTITION BY lm.date, lm.external_student_id, lm.subject, lm.app ORDER BY lm.mastered_at ASC NULLS LAST, lm.id ASC) lesson_rn
   FROM
     studient.level_mastery lm
   WHERE ((lm.date >= DATE '2025-01-01') AND REGEXP_LIKE(lm.external_student_id, '^[0-9]+$'))
) 
, lesson_with_roster AS (
   SELECT
     lb.*
   , r.full_student_id
   , r.campus_id
   , r.campus_name
   , COALESCE(ast.student_group, r.campus_name) school_name
   , ast.student_group
   , r.grade
   , r.level student_level
   , r.teacher_name
   , r.teacher_email
   , ast.advisoremail advisor_email
   , r.student_name
   , r.externalstudentid
   , ROW_NUMBER() OVER (PARTITION BY lb.lesson_id ORDER BY r.campus_id ASC) roster_dedup
   FROM
     ((lesson_base lb
   INNER JOIN studient.khiem_v_roster r ON (lb.external_student_id = r.external_student_id))
   LEFT JOIN alpha_student_dedup ast ON (r.full_student_id = ast.fullid))
   WHERE (r.campus_id IN (SELECT campus_id
FROM
  target_campuses
))
) 
, lesson_final AS (
   SELECT *
   FROM
     lesson_with_roster
   WHERE (roster_dedup = 1)
) 
, ixl_course_grade_parsed AS (
   SELECT
     lf.lesson_id
   , lf.course
   , (CASE WHEN REGEXP_LIKE(lf.course, ' - [0-9]+$') THEN TRY_CAST(REGEXP_EXTRACT(lf.course, ' - ([0-9]+)$', 1) AS INTEGER) WHEN REGEXP_LIKE(LOWER(lf.course), ' - k$') THEN 0 WHEN REGEXP_LIKE(LOWER(lf.course), ' - pk$') THEN -1 WHEN REGEXP_LIKE(LOWER(lf.course), 'kindergarten') THEN 0 WHEN REGEXP_LIKE(LOWER(lf.course), 'pre-k') THEN -1 ELSE null END) parsed_course_grade
   FROM
     lesson_final lf
   WHERE (LOWER(lf.app) = 'ixl')
) 
, activity_unmatched AS (
   SELECT
     dt.date activity_date
   , dt.full_student_id
   , CONCAT(UPPER(SUBSTR(trim(BOTH FROM dt.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM dt.subject), 2))) subject_display
   , (CASE WHEN (LOWER(trim(BOTH FROM dt.subject)) = 'reading') THEN 'Reading' WHEN (LOWER(trim(BOTH FROM dt.subject)) = 'language') THEN 'Language' WHEN (LOWER(trim(BOTH FROM dt.subject)) = 'math') THEN 'Math' WHEN (LOWER(trim(BOTH FROM dt.subject)) = 'science') THEN 'Science' WHEN (LOWER(trim(BOTH FROM dt.subject)) = 'social studies') THEN 'Social Studies' ELSE CONCAT(UPPER(SUBSTR(trim(BOTH FROM dt.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM dt.subject), 2))) END) subject
   , dt.app
   , dt.daily_minutes
   , dt.course
   , r.student_name
   , r.campus_id
   , r.campus_name
   , COALESCE(ast.student_group, r.campus_name) school_name
   , ast.student_group
   , r.grade
   , r.level student_level
   , r.teacher_name
   , r.teacher_email
   , ast.advisoremail advisor_email
   , r.externalstudentid
   FROM
     (((studient.khiem_v_daily_time dt
   INNER JOIN studient.khiem_v_roster r ON (dt.full_student_id = r.full_student_id))
   LEFT JOIN alpha_student_dedup ast ON (r.full_student_id = ast.fullid))
   LEFT JOIN lesson_final lf ON ((dt.full_student_id = lf.full_student_id) AND (dt.date = lf.lesson_date) AND (LOWER(trim(BOTH FROM dt.subject)) = LOWER(lf.subject)) AND (LOWER(dt.app) = LOWER(lf.app))))
   WHERE ((dt.date >= DATE '2025-01-01') AND (r.campus_id IN (SELECT campus_id
FROM
  target_campuses
)) AND (lf.lesson_id IS NULL) AND (dt.daily_minutes > 0))
) 
, targets_map AS (
   SELECT
     full_student_id
   , date
   , subject
   , app
   , COALESCE(TRY_CAST(daily_mastery_target AS INTEGER), 0) target
   FROM
     studient.khiem_v_daily_targets
) 
, nwea_clean AS (
   SELECT
     full_student_id
   , subject_lower
   , fall_rit
   , winter_rit
   , spring_rit
   , fall_cgp
   , winter_cgp
   , spring_cgp
   , f2w_projected_growth
   , f2w_observed_growth
   , TRY_CAST(NULLIF(trim(BOTH FROM f2w_projected_growth), '') AS DOUBLE) f2w_projected_growth_num
   , TRY_CAST(NULLIF(trim(BOTH FROM f2w_observed_growth), '') AS DOUBLE) f2w_observed_growth_num
   FROM
     studient.khiem_v_nwea_comprehensive
) 
, cumulative_agg AS (
   SELECT
     student_id
   , activity_date
   , subject
   , app
   , SUM(essential_levels_mastered_eng) daily_essential_count
   , SUM(SUM(essential_levels_mastered_eng)) OVER (PARTITION BY student_id, subject, app ORDER BY activity_date ASC) running_total_essential
   FROM
     studient.khiem_v_student_essential_mastery_from_lm
   GROUP BY 1, 2, 3, 4
) 
, taken_tests AS (
   SELECT
     ts.student_id
   , LOWER(trim(BOTH FROM ts.subject)) subject_lower
   , ts.date test_date
   FROM
     studient.khiem_v_test_scores_final ts
   WHERE ((ts.date >= DATE '2025-01-01') AND (LOWER(ts.source_system) = 'edulastic'))
) 
, all_records AS (
   SELECT
     'Lesson' row_type
   , false is_test
   , lf.lesson_date activity_date
   , lf.full_student_id student_id
   , lf.student_name
   , lf.campus_id
   , lf.campus_name
   , lf.school_name
   , lf.student_group
   , lf.grade
   , lf.student_level level
   , lf.teacher_name
   , lf.teacher_email
   , lf.advisor_email
   , lf.subject_display
   , lf.subject
   , lf.app
   , lf.course
   , lf.active_minutes minutes_raw
   , (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY lf.full_student_id, lf.lesson_date, lf.app, lf.active_minutes ORDER BY lf.lesson_id ASC) = 1) THEN lf.active_minutes ELSE 0 END) minutes_working
   , lf.is_mastered units_mastered
   , lf.activity_units_correct correct_questions
   , lf.activity_units_attempted total_questions
   , (CASE WHEN (lf.activity_units_attempted > 0) THEN ROUND((CAST(lf.activity_units_correct AS DOUBLE) / lf.activity_units_attempted), 4) ELSE null END) accuracy
   , CAST(null AS VARCHAR) antipatterns
   , CAST(null AS INTEGER) antipattern_count
   , CAST(null AS VARCHAR) learning_level
   , CAST(null AS VARCHAR) learning_unit_passed
   , lf.is_essential essential_units_attempted
   , COALESCE(cum.daily_essential_count, 0) essential_units_mastered
   , lf.is_mastered levels_mastered
   , (CASE WHEN (lf.lesson_rn = 1) THEN t.target ELSE null END) daily_mastery_target
   , CAST(null AS DOUBLE) mastery_vs_daily_target_pct
   , CAST(null AS INTEGER) variance_vs_daily_target
   , CAST(null AS VARCHAR) target_status
   , lf.lesson_name
   , lf.topic
   , lf.mastery_percentage
   , lf.status lesson_status
   , lf.resource_type
   , lf.lesson_url
   , lf.lesson_id
   , CAST(null AS VARCHAR) test_source
   , CAST(null AS VARCHAR) test_name
   , CAST(null AS VARCHAR) test_type
   , CAST(null AS DOUBLE) test_score
   , CAST(null AS DOUBLE) test_max_score
   , CAST(null AS DOUBLE) test_accuracy
   , CAST(null AS VARCHAR) test_result
   , nwea.fall_rit
   , nwea.winter_rit
   , nwea.spring_rit
   , nwea.fall_cgp
   , nwea.winter_cgp
   , nwea.spring_cgp
   , nwea.f2w_projected_growth
   , nwea.f2w_observed_growth
   , COALESCE(cum.daily_essential_count, 0) essential_levels_mastered_eng
   , COALESCE(cum.running_total_essential, 0) total_mastered_essential_levels_eng
   , CAST((CASE WHEN (LOWER(lf.app) = 'amplify') THEN 220 WHEN (LOWER(lf.app) = 'alpha reading') THEN 140 WHEN (LOWER(lf.app) = 'mathacademy') THEN 300 WHEN (LOWER(lf.app) = 'lalilo') THEN 180 WHEN (LOWER(lf.app) = 'zearn') THEN 200 WHEN (LOWER(lf.app) = 'freckle') THEN 150 WHEN (LOWER(lf.app) = 'ixl') THEN COALESCE(ixl_course.total_essential_skills, ixl_knowledge.total_essential_skills, ixl.total_essential_skills, 130) ELSE COALESCE(cet.total_course_essential_levels, 100) END) AS DOUBLE) avg_essential_lessons_hardcoded
   , CAST(AVG((CASE WHEN (LOWER(lf.app) = 'amplify') THEN 220 WHEN (LOWER(lf.app) = 'alpha reading') THEN 140 WHEN (LOWER(lf.app) = 'mathacademy') THEN 300 WHEN (LOWER(lf.app) = 'lalilo') THEN 180 WHEN (LOWER(lf.app) = 'zearn') THEN 200 WHEN (LOWER(lf.app) = 'freckle') THEN 150 WHEN (LOWER(lf.app) = 'ixl') THEN COALESCE(ixl_course.total_essential_skills, ixl_knowledge.total_essential_skills, ixl.total_essential_skills, 130) ELSE COALESCE(cet.total_course_essential_levels, 100) END)) OVER (PARTITION BY lf.full_student_id, LOWER(lf.subject)) AS DOUBLE) avg_essential_lessons_quicksight
   , CAST(((AVG((CASE WHEN (LOWER(lf.app) = 'amplify') THEN 220 WHEN (LOWER(lf.app) = 'alpha reading') THEN 140 WHEN (LOWER(lf.app) = 'mathacademy') THEN 300 WHEN (LOWER(lf.app) = 'lalilo') THEN 180 WHEN (LOWER(lf.app) = 'zearn') THEN 200 WHEN (LOWER(lf.app) = 'freckle') THEN 150 WHEN (LOWER(lf.app) = 'ixl') THEN COALESCE(ixl_course.total_essential_skills, ixl_knowledge.total_essential_skills, ixl.total_essential_skills, 130) ELSE COALESCE(cet.total_course_essential_levels, 100) END)) OVER (PARTITION BY lf.full_student_id, LOWER(lf.subject)) * 2E0) / 1.8E2) AS DOUBLE) grade_completion_target_day_quicksight
   , CAST((CASE WHEN (LOWER(lf.app) = 'ixl') THEN COALESCE(ixl_knowledge.total_essential_skills, ixl.total_essential_skills, 130) ELSE COALESCE(cet.total_course_essential_levels, 100) END) AS DOUBLE) total_course_essential_levels_eng
   , CAST((((CASE WHEN (LOWER(lf.app) = 'amplify') THEN 220 WHEN (LOWER(lf.app) = 'alpha reading') THEN 140 WHEN (LOWER(lf.app) = 'mathacademy') THEN 300 WHEN (LOWER(lf.app) = 'lalilo') THEN 180 WHEN (LOWER(lf.app) = 'zearn') THEN 200 WHEN (LOWER(lf.app) = 'freckle') THEN 150 WHEN (LOWER(lf.app) = 'ixl') THEN COALESCE(ixl_knowledge.total_essential_skills, ixl.total_essential_skills, 130) ELSE COALESCE(cet.total_course_essential_levels, 100) END) * 2E0) / 1.8E2) AS DOUBLE) grade_completion_target_day
   , (CASE WHEN ((nwea.f2w_projected_growth_num IS NOT NULL) AND (nwea.f2w_projected_growth_num <> 0) AND (nwea.f2w_observed_growth_num IS NOT NULL)) THEN (nwea.f2w_observed_growth_num / nwea.f2w_projected_growth_num) ELSE null END) map_growth_score
   , CAST(null AS DOUBLE) x_growth
   , bh.onboarding_status
   , TRY_CAST(bh.knowledge_grade AS INTEGER) knowledge_grade
   , lf.lesson_rn
   , CAST(null AS VARCHAR) test_group_key
   , CAST(null AS VARCHAR) knowledge_grade_label
   , CAST(null AS VARCHAR) grade_source
   , CAST(null AS INTEGER) days_since_assignment
   , CAST(null AS BOOLEAN) is_active_assignment
   , bh.notes
   , lf.externalstudentid
   FROM
     (((((((((lesson_final lf
   LEFT JOIN targets_map t ON ((lf.full_student_id = t.full_student_id) AND (lf.lesson_date = t.date) AND (LOWER(lf.subject) = LOWER(t.subject)) AND (LOWER(lf.app) = LOWER(t.app))))
   LEFT JOIN nwea_clean nwea ON ((lf.full_student_id = nwea.full_student_id) AND (LOWER(lf.subject) = nwea.subject_lower)))
   LEFT JOIN studient.khiem_v_bracketing_history_ranges bh ON ((lf.full_student_id = bh.full_student_id) AND (LOWER(lf.subject) = bh.subject) AND ((lf.lesson_date >= bh.valid_from_date) AND (lf.lesson_date <= bh.valid_to_date))))
   LEFT JOIN studient.khiem_v_course_essential_totals cet ON ((LOWER(lf.app) = cet.app) AND (LOWER(lf.subject) = cet.subject) AND (lf.course = cet.course)))
   LEFT JOIN cumulative_agg cum ON ((lf.full_student_id = cum.student_id) AND (lf.lesson_date = cum.activity_date) AND (LOWER(lf.subject) = LOWER(cum.subject)) AND (LOWER(lf.app) = LOWER(cum.app)) AND (lf.lesson_rn = 1)))
   LEFT JOIN ixl_grade_lookup ixl ON ((LOWER(lf.app) = LOWER(ixl.app)) AND (LOWER(lf.subject) = LOWER(ixl.subject)) AND (TRY_CAST(lf.grade AS INTEGER) = ixl.numeric_grade)))
   LEFT JOIN ixl_grade_lookup ixl_knowledge ON ((LOWER(lf.app) = LOWER(ixl_knowledge.app)) AND (LOWER(lf.subject) = LOWER(ixl_knowledge.subject)) AND (TRY_CAST(bh.knowledge_grade AS INTEGER) = ixl_knowledge.numeric_grade)))
   LEFT JOIN ixl_course_grade_parsed parsed ON (lf.lesson_id = parsed.lesson_id))
   LEFT JOIN ixl_grade_lookup ixl_course ON ((LOWER(lf.app) = LOWER(ixl_course.app)) AND (LOWER(lf.subject) = LOWER(ixl_course.subject)) AND (parsed.parsed_course_grade = ixl_course.numeric_grade)))
UNION ALL    SELECT
     'Activity' row_type
   , false is_test
   , au.activity_date
   , au.full_student_id student_id
   , au.student_name
   , au.campus_id
   , au.campus_name
   , au.school_name
   , au.student_group
   , au.grade
   , au.student_level level
   , au.teacher_name
   , au.teacher_email
   , au.advisor_email
   , au.subject_display
   , au.subject
   , au.app
   , au.course
   , au.daily_minutes minutes_raw
   , au.daily_minutes minutes_working
   , 0 units_mastered
   , 0 correct_questions
   , 0 total_questions
   , CAST(null AS DOUBLE) accuracy
   , CAST(null AS VARCHAR) antipatterns
   , CAST(null AS INTEGER) antipattern_count
   , CAST(null AS VARCHAR) learning_level
   , CAST(null AS VARCHAR) learning_unit_passed
   , 0 essential_units_attempted
   , 0 essential_units_mastered
   , 0 levels_mastered
   , t.target daily_mastery_target
   , CAST(null AS DOUBLE) mastery_vs_daily_target_pct
   , CAST(null AS INTEGER) variance_vs_daily_target
   , CAST(null AS VARCHAR) target_status
   , 'Unaccounted Activity' lesson_name
   , CAST(null AS VARCHAR) topic
   , CAST(null AS DOUBLE) mastery_percentage
   , CAST(null AS VARCHAR) lesson_status
   , CAST(null AS VARCHAR) resource_type
   , CAST(null AS VARCHAR) lesson_url
   , CAST(null AS VARCHAR) lesson_id
   , CAST(null AS VARCHAR) test_source
   , CAST(null AS VARCHAR) test_name
   , CAST(null AS VARCHAR) test_type
   , CAST(null AS DOUBLE) test_score
   , CAST(null AS DOUBLE) test_max_score
   , CAST(null AS DOUBLE) test_accuracy
   , CAST(null AS VARCHAR) test_result
   , nwea.fall_rit
   , nwea.winter_rit
   , nwea.spring_rit
   , nwea.fall_cgp
   , nwea.winter_cgp
   , nwea.spring_cgp
   , nwea.f2w_projected_growth
   , nwea.f2w_observed_growth
   , COALESCE(cum.daily_essential_count, 0) essential_levels_mastered_eng
   , COALESCE(cum.running_total_essential, 0) total_mastered_essential_levels_eng
   , CAST((CASE WHEN (LOWER(au.app) = 'amplify') THEN 220 WHEN (LOWER(au.app) = 'alpha reading') THEN 140 WHEN (LOWER(au.app) = 'mathacademy') THEN 300 WHEN (LOWER(au.app) = 'lalilo') THEN 180 WHEN (LOWER(au.app) = 'zearn') THEN 200 WHEN (LOWER(au.app) = 'freckle') THEN 150 WHEN (LOWER(au.app) = 'ixl') THEN COALESCE(ixl_au.total_essential_skills, 130) ELSE 100 END) AS DOUBLE) avg_essential_lessons_hardcoded
   , CAST((CASE WHEN (LOWER(au.app) = 'amplify') THEN 220 WHEN (LOWER(au.app) = 'alpha reading') THEN 140 WHEN (LOWER(au.app) = 'mathacademy') THEN 300 WHEN (LOWER(au.app) = 'lalilo') THEN 180 ELSE 100 END) AS DOUBLE) avg_essential_lessons_quicksight
   , CAST((((CASE WHEN (LOWER(au.app) = 'amplify') THEN 220 WHEN (LOWER(au.app) = 'alpha reading') THEN 140 WHEN (LOWER(au.app) = 'mathacademy') THEN 300 WHEN (LOWER(au.app) = 'lalilo') THEN 180 ELSE 100 END) * 2E0) / 1.8E2) AS DOUBLE) grade_completion_target_day_quicksight
   , CAST((CASE WHEN (LOWER(au.app) = 'ixl') THEN COALESCE(ixl_au.total_essential_skills, 130) ELSE 100 END) AS DOUBLE) total_course_essential_levels_eng
   , CAST((((CASE WHEN (LOWER(au.app) = 'amplify') THEN 220 WHEN (LOWER(au.app) = 'alpha reading') THEN 140 WHEN (LOWER(au.app) = 'mathacademy') THEN 300 WHEN (LOWER(au.app) = 'lalilo') THEN 180 WHEN (LOWER(au.app) = 'zearn') THEN 200 WHEN (LOWER(au.app) = 'freckle') THEN 150 WHEN (LOWER(au.app) = 'ixl') THEN COALESCE(ixl_au.total_essential_skills, 130) ELSE 100 END) * 2E0) / 1.8E2) AS DOUBLE) grade_completion_target_day
   , (CASE WHEN ((nwea.f2w_projected_growth_num IS NOT NULL) AND (nwea.f2w_projected_growth_num <> 0) AND (nwea.f2w_observed_growth_num IS NOT NULL)) THEN (nwea.f2w_observed_growth_num / nwea.f2w_projected_growth_num) ELSE null END) map_growth_score
   , CAST(null AS DOUBLE) x_growth
   , bh.onboarding_status
   , TRY_CAST(bh.knowledge_grade AS INTEGER) knowledge_grade
   , CAST(null AS INTEGER) lesson_rn
   , CAST(null AS VARCHAR) test_group_key
   , CAST(null AS VARCHAR) knowledge_grade_label
   , CAST(null AS VARCHAR) grade_source
   , CAST(null AS INTEGER) days_since_assignment
   , CAST(null AS BOOLEAN) is_active_assignment
   , CAST(null AS VARCHAR) notes
   , au.externalstudentid
   FROM
     (((((activity_unmatched au
   LEFT JOIN targets_map t ON ((au.full_student_id = t.full_student_id) AND (au.activity_date = t.date) AND (LOWER(au.subject) = LOWER(t.subject)) AND (LOWER(au.app) = LOWER(t.app))))
   LEFT JOIN nwea_clean nwea ON ((au.full_student_id = nwea.full_student_id) AND (LOWER(au.subject) = nwea.subject_lower)))
   LEFT JOIN studient.khiem_v_bracketing_history_ranges bh ON ((au.full_student_id = bh.full_student_id) AND (LOWER(au.subject) = bh.subject) AND ((au.activity_date >= bh.valid_from_date) AND (au.activity_date <= bh.valid_to_date))))
   LEFT JOIN cumulative_agg cum ON ((au.full_student_id = cum.student_id) AND (au.activity_date = cum.activity_date) AND (LOWER(au.subject) = LOWER(cum.subject)) AND (LOWER(au.app) = LOWER(cum.app))))
   LEFT JOIN ixl_grade_lookup ixl_au ON ((LOWER(au.app) = LOWER(ixl_au.app)) AND (LOWER(au.subject) = LOWER(ixl_au.subject)) AND (TRY_CAST(au.grade AS INTEGER) = ixl_au.numeric_grade)))
UNION ALL    SELECT
     'Test' row_type
   , true is_test
   , ts.date activity_date
   , ts.student_id
   , ts.student_name
   , r.campus_id
   , r.campus_name
   , COALESCE(ast.student_group, r.campus_name) school_name
   , ast.student_group
   , r.grade
   , r.level
   , r.teacher_name
   , r.teacher_email
   , ast.advisoremail advisor_email
   , CONCAT(UPPER(SUBSTR(trim(BOTH FROM ts.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM ts.subject), 2))) subject_display
   , (CASE WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'reading') THEN 'Reading' WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'language') THEN 'Language' WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'math') THEN 'Math' WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'science') THEN 'Science' WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'social studies') THEN 'Social Studies' WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'writing') THEN 'Writing' WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'fast math') THEN 'Fast Math' ELSE CONCAT(UPPER(SUBSTR(trim(BOTH FROM ts.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM ts.subject), 2))) END) subject
   , CAST(null AS VARCHAR) app
   , CAST(null AS VARCHAR) course
   , CAST(null AS DOUBLE) minutes_raw
   , CAST(null AS DOUBLE) minutes_working
   , 0 units_mastered
   , CAST(null AS INTEGER) correct_questions
   , CAST(null AS INTEGER) total_questions
   , CAST(null AS DOUBLE) accuracy
   , CAST(null AS VARCHAR) antipatterns
   , CAST(null AS INTEGER) antipattern_count
   , CAST(null AS VARCHAR) learning_level
   , CAST(null AS VARCHAR) learning_unit_passed
   , 0 essential_units_attempted
   , 0 essential_units_mastered
   , 0 levels_mastered
   , CAST(null AS INTEGER) daily_mastery_target
   , CAST(null AS DOUBLE) mastery_vs_daily_target_pct
   , CAST(null AS INTEGER) variance_vs_daily_target
   , CAST(null AS VARCHAR) target_status
   , CAST(null AS VARCHAR) lesson_name
   , CAST(null AS VARCHAR) topic
   , CAST(null AS DOUBLE) mastery_percentage
   , CAST(null AS VARCHAR) lesson_status
   , CAST(null AS VARCHAR) resource_type
   , CAST(null AS VARCHAR) lesson_url
   , CAST(null AS VARCHAR) lesson_id
   , ts.source_system test_source
   , RTRIM(ts.test_name, '.') test_name
   , ts.test_type
   , ts.score test_score
   , ts.max_score test_max_score
   , ts.accuracy_pct test_accuracy
   , ts.pass_fail test_result
   , nwea.fall_rit
   , nwea.winter_rit
   , nwea.spring_rit
   , nwea.fall_cgp
   , nwea.winter_cgp
   , nwea.spring_cgp
   , nwea.f2w_projected_growth
   , nwea.f2w_observed_growth
   , 0 essential_levels_mastered_eng
   , 0 total_mastered_essential_levels_eng
   , CAST(null AS DOUBLE) avg_essential_lessons_hardcoded
   , CAST(null AS DOUBLE) avg_essential_lessons_quicksight
   , CAST(null AS DOUBLE) grade_completion_target_day_quicksight
   , CAST(null AS DOUBLE) total_course_essential_levels_eng
   , CAST(null AS DOUBLE) grade_completion_target_day
   , (CASE WHEN ((nwea.f2w_projected_growth_num IS NOT NULL) AND (nwea.f2w_projected_growth_num <> 0) AND (nwea.f2w_observed_growth_num IS NOT NULL)) THEN (nwea.f2w_observed_growth_num / nwea.f2w_projected_growth_num) ELSE null END) map_growth_score
   , CAST(null AS DOUBLE) x_growth
   , bh.onboarding_status
   , COALESCE(TRY_CAST(ti.grade AS INTEGER), TRY_CAST(bh.knowledge_grade AS INTEGER)) knowledge_grade
   , CAST(null AS INTEGER) lesson_rn
   , CONCAT((CASE WHEN (LOWER(trim(BOTH FROM ts.subject)) IN ('reading', 'language')) THEN 'language' WHEN (LOWER(trim(BOTH FROM ts.subject)) = 'math') THEN 'math' ELSE LOWER(trim(BOTH FROM ts.subject)) END), '_', COALESCE(CAST(TRY_CAST(ti.grade AS INTEGER) AS VARCHAR), CAST(TRY_CAST(bh.knowledge_grade AS INTEGER) AS VARCHAR), 'UNK')) test_group_key
   , (CASE WHEN (COALESCE(TRY_CAST(ti.grade AS INTEGER), TRY_CAST(bh.knowledge_grade AS INTEGER)) IS NULL) THEN 'Unknown' WHEN (COALESCE(TRY_CAST(ti.grade AS INTEGER), TRY_CAST(bh.knowledge_grade AS INTEGER)) = -1) THEN 'Pre-K' WHEN (COALESCE(TRY_CAST(ti.grade AS INTEGER), TRY_CAST(bh.knowledge_grade AS INTEGER)) = 0) THEN 'Kindergarten' ELSE CONCAT('Grade ', CAST(COALESCE(TRY_CAST(ti.grade AS INTEGER), TRY_CAST(bh.knowledge_grade AS INTEGER)) AS VARCHAR)) END) knowledge_grade_label
   , (CASE WHEN (TRY_CAST(ti.grade AS INTEGER) IS NOT NULL) THEN 'test_inventory' WHEN (bh.knowledge_grade IS NOT NULL) THEN 'bracketing' ELSE 'unknown' END) grade_source
   , CAST(null AS INTEGER) days_since_assignment
   , CAST(null AS BOOLEAN) is_active_assignment
   , bh.notes
   , r.externalstudentid
   FROM
     (((((studient.khiem_v_test_scores_final ts
   INNER JOIN studient.khiem_v_roster r ON (ts.student_id = r.full_student_id))
   LEFT JOIN alpha_student_dedup ast ON (ts.student_id = ast.fullid))
   LEFT JOIN nwea_clean nwea ON ((r.full_student_id = nwea.full_student_id) AND (LOWER(trim(BOTH FROM ts.subject)) = nwea.subject_lower)))
   LEFT JOIN studient.khiem_v_bracketing_history_ranges bh ON ((r.full_student_id = bh.full_student_id) AND (LOWER(trim(BOTH FROM ts.subject)) = bh.subject) AND ((ts.date >= bh.valid_from_date) AND (ts.date <= bh.valid_to_date))))
   LEFT JOIN studient.edulastic_test_inventory ti ON (RTRIM(ts.test_name, '.') = ti.title))
   WHERE ((ts.date >= DATE '2025-01-01') AND (r.campus_id IN (SELECT campus_id
FROM
  target_campuses
)) AND (NOT ((ts.test_name LIKE '%.') AND (EXISTS (SELECT 1
FROM
  studient.khiem_v_test_scores_final ts2
WHERE ((ts2.student_id = ts.student_id) AND (ts2.date = ts.date) AND (ts2.test_name = RTRIM(ts.test_name, '.')) AND (ts2.accuracy_pct = ts.accuracy_pct))
)))))
UNION ALL    SELECT
     'Bracketing Assignment' row_type
   , false is_test
   , CAST(from_iso8601_timestamp(ba.assigned_on) AS DATE) activity_date
   , ba.full_student_id student_id
   , r.student_name
   , r.campus_id
   , r.campus_name
   , COALESCE(ast.student_group, r.campus_name) school_name
   , ast.student_group
   , r.grade
   , r.level
   , r.teacher_name
   , r.teacher_email
   , ast.advisoremail advisor_email
   , CONCAT(UPPER(SUBSTR(trim(BOTH FROM ba.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM ba.subject), 2))) subject_display
   , (CASE WHEN (LOWER(trim(BOTH FROM ba.subject)) = 'reading') THEN 'Reading' WHEN (LOWER(trim(BOTH FROM ba.subject)) = 'language') THEN 'Language' WHEN (LOWER(trim(BOTH FROM ba.subject)) = 'math') THEN 'Math' ELSE CONCAT(UPPER(SUBSTR(trim(BOTH FROM ba.subject), 1, 1)), LOWER(SUBSTR(trim(BOTH FROM ba.subject), 2))) END) subject
   , CAST(null AS VARCHAR) app
   , CAST(null AS VARCHAR) course
   , CAST(null AS DOUBLE) minutes_raw
   , CAST(null AS DOUBLE) minutes_working
   , 0 units_mastered
   , CAST(null AS INTEGER) correct_questions
   , CAST(null AS INTEGER) total_questions
   , CAST(null AS DOUBLE) accuracy
   , CAST(null AS VARCHAR) antipatterns
   , CAST(null AS INTEGER) antipattern_count
   , CAST(null AS VARCHAR) learning_level
   , CAST(null AS VARCHAR) learning_unit_passed
   , 0 essential_units_attempted
   , CAST(null AS BIGINT) essential_units_mastered
   , 0 levels_mastered
   , CAST(null AS INTEGER) daily_mastery_target
   , CAST(null AS DOUBLE) mastery_vs_daily_target_pct
   , CAST(null AS INTEGER) variance_vs_daily_target
   , CAST(null AS VARCHAR) target_status
   , CAST(null AS VARCHAR) lesson_name
   , CAST(null AS VARCHAR) topic
   , CAST(null AS DOUBLE) mastery_percentage
   , CAST(null AS VARCHAR) lesson_status
   , CAST(null AS VARCHAR) resource_type
   , CAST(null AS VARCHAR) lesson_url
   , CAST(null AS VARCHAR) lesson_id
   , 'Bracketing System' test_source
   , COALESCE(ti.title, CAST(ba.test_key AS VARCHAR)) test_name
   , 'Bracketing Test' test_type
   , CAST(null AS DOUBLE) test_score
   , CAST(null AS DOUBLE) test_max_score
   , CAST(null AS DOUBLE) test_accuracy
   , CAST(null AS VARCHAR) test_result
   , CAST(null AS VARCHAR) fall_rit
   , CAST(null AS VARCHAR) winter_rit
   , CAST(null AS VARCHAR) spring_rit
   , CAST(null AS VARCHAR) fall_cgp
   , CAST(null AS VARCHAR) winter_cgp
   , CAST(null AS VARCHAR) spring_cgp
   , CAST(null AS VARCHAR) f2w_projected_growth
   , CAST(null AS VARCHAR) f2w_observed_growth
   , CAST(null AS BIGINT) essential_levels_mastered_eng
   , CAST(null AS BIGINT) total_mastered_essential_levels_eng
   , CAST(null AS DOUBLE) avg_essential_lessons_hardcoded
   , CAST(null AS DOUBLE) avg_essential_lessons_quicksight
   , CAST(null AS DOUBLE) grade_completion_target_day_quicksight
   , CAST(null AS DOUBLE) total_course_essential_levels_eng
   , CAST(null AS DOUBLE) grade_completion_target_day
   , CAST(null AS DOUBLE) map_growth_score
   , CAST(null AS DOUBLE) x_growth
   , ba.onboarding_status
   , TRY_CAST(ba.grade AS INTEGER) knowledge_grade
   , CAST(null AS BIGINT) lesson_rn
   , CONCAT((CASE WHEN (LOWER(trim(BOTH FROM ba.subject)) = 'reading') THEN 'language' WHEN (LOWER(trim(BOTH FROM ba.subject)) = 'math') THEN 'math' ELSE LOWER(trim(BOTH FROM ba.subject)) END), '_', COALESCE(CAST(TRY_CAST(ba.grade AS INTEGER) AS VARCHAR), 'UNK')) test_group_key
   , (CASE WHEN (TRY_CAST(ba.grade AS INTEGER) IS NULL) THEN 'Unknown' WHEN (TRY_CAST(ba.grade AS INTEGER) = -1) THEN 'Pre-K' WHEN (TRY_CAST(ba.grade AS INTEGER) = 0) THEN 'Kindergarten' ELSE CONCAT('Grade ', CAST(TRY_CAST(ba.grade AS INTEGER) AS VARCHAR)) END) knowledge_grade_label
   , 'bracketing_assignment' grade_source
   , DATE_DIFF('day', CAST(from_iso8601_timestamp(ba.assigned_on) AS DATE), current_date) days_since_assignment
   , (CASE WHEN (((ba.invalidated_on IS NULL) OR (trim(BOTH FROM ba.invalidated_on) = '')) AND (tt.test_date IS NULL)) THEN true ELSE false END) is_active_assignment
   , ba.notes notes
   , r.externalstudentid
   FROM
     ((((studient.bracketing_assignments ba
   INNER JOIN studient.khiem_v_roster r ON (ba.full_student_id = r.full_student_id))
   LEFT JOIN alpha_student_dedup ast ON (r.full_student_id = ast.fullid))
   LEFT JOIN studient.edulastic_test_inventory ti ON (ba.test_key = ti.id))
   LEFT JOIN taken_tests tt ON ((ba.full_student_id = tt.student_id) AND (LOWER(trim(BOTH FROM ba.subject)) = tt.subject_lower) AND (tt.test_date >= CAST(from_iso8601_timestamp(ba.assigned_on) AS DATE))))
   WHERE ((ba.assigned_on IS NOT NULL) AND (trim(BOTH FROM ba.full_student_id) <> '') AND (r.campus_id IN (SELECT campus_id
FROM
  target_campuses
)) AND (CAST(from_iso8601_timestamp(ba.assigned_on) AS DATE) >= DATE '2025-01-01'))
) 
SELECT deduped.*
  , frp.first_placed AS first_placed_date
  , CASE WHEN deduped.activity_date > frp.first_placed THEN TRUE ELSE FALSE END AS placed_before_activity
FROM
  (
   SELECT
     ar.*
   , ROW_NUMBER() OVER (PARTITION BY ar.student_id, ar.activity_date, ar.row_type, COALESCE(ar.app, ''), ar.subject, COALESCE(ar.lesson_id, ''), COALESCE(ar.test_name, ''), COALESCE(ar.test_source, ''), COALESCE(CAST(ar.test_score AS VARCHAR), '') ORDER BY ar.minutes_working DESC NULLS LAST, ar.knowledge_grade DESC NULLS LAST) dedupe_rn
   FROM
     all_records ar
)  deduped
LEFT JOIN first_real_placement frp ON deduped.student_id = frp.full_student_id
    AND LOWER(deduped.subject) = frp.subject
WHERE (dedupe_rn = 1)
