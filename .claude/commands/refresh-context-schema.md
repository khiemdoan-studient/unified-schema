---
description: Reload Unified Schema context post-compaction. Reads docs, diagrams, and the 3 primary output views to understand the complete Athena data model.
---

Do these steps in order:

1. **Compact conversation history** to save memory and optimize performance.

2. **Read all project documentation** to get back to speed:
   - Read `C:\Users\doank\Documents\Projects\unified-schema\README.md`
   - Read `C:\Users\doank\Documents\Projects\unified-schema\docs\AI_INSTRUCTIONS.md` — primary context doc
   - Read `C:\Users\doank\Documents\Projects\unified-schema\docs\CHANGELOG.md` — recent schema changes
   - Read `C:\Users\doank\Documents\Projects\unified-schema\docs\SCHEMA_REFERENCE.md` — full schema catalog
   - Read `C:\Users\doank\Documents\Projects\unified-schema\diagrams\dependency_tree.md` — view dependency chain

3. **Read the 3 primary output views** (the foundation of all downstream pipelines):
   - Read `C:\Users\doank\Documents\Projects\unified-schema\ddl\views\khiem_v_lesson_unified.sql` — unified activity/test/bracketing events
   - Read `C:\Users\doank\Documents\Projects\unified-schema\ddl\views\khiem_v_weekly_dashboard.sql` — per-student-week rollup
   - Read `C:\Users\doank\Documents\Projects\unified-schema\ddl\views\khiem_v_doom_loop_students.sql` — intervention tracking

4. **Understand the scope**:
   - 28 views + 21 external tables in the `studient` database (AWS Athena, us-east-1)
   - 3 primary output views feed: `student_activity_unified`, `weekly_dashboard`, `doom_loop_students` BigQuery tables
   - Most views filter to `activity_date >= DATE '2025-01-01'` and 12 target campus IDs

5. **Cross-project dependencies**:
   - The pipeline project (Studient Excel Automation) imports these views via CTAS → S3 → BigQuery
   - Schema changes here require a pipeline re-run to propagate

## Suggested Next Steps

Based on the user's ask:
- **View/DDL changes:** `/build-checklist` → edit SQL → test with LIMIT → `/verify-build` → `/update-docs`
- **New view analysis:** Trace dependencies via `diagrams/dependency_tree.md` first
- **Downstream impact:** Changes here require pipeline re-run (`Refresh-Data.ps1` in Studient Excel Automation)
- **Broad review:** `/audit` for SQL issues + efficiency
- **Ambiguous:** Ask clarifying questions about scope and acceptance criteria

After reading, confirm you understand the data model and are ready for the user's next task.
