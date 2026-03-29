# Diagrams

## Interactive ERD (Recommended)

**[`interactive-erd.html`](interactive-erd.html)** — Open this file in any browser for a professional, zoomable, pannable ERD viewer.

Features:
- **Scroll** to zoom in/out
- **Click + drag** to pan
- **Double-click** to fit to screen
- **5 focused views** via toolbar buttons (or press 1-5):
  1. Full Schema (all entities)
  2. Lesson Unified (direct dependencies only)
  3. Weekly Dashboard + Doom Loop
  4. Essential Skills pipeline
  5. Tests & Identity Resolution
- Dark theme matching GitHub

To use: download the file and open in Chrome/Firefox/Edge, or enable GitHub Pages on this repo.

## Focused Sub-Diagrams (GitHub-rendered)

These are small enough to render readably on GitHub:

| File | What It Shows |
|------|---------------|
| [`erd_lesson_unified.mmd`](erd_lesson_unified.mmd) | `khiem_v_lesson_unified` and its 12 direct dependencies |
| [`erd_weekly_and_doom_loop.mmd`](erd_weekly_and_doom_loop.mmd) | `khiem_v_weekly_dashboard` + `khiem_v_doom_loop_students` |
| [`erd_tests_and_identity.mmd`](erd_tests_and_identity.mmd) | Test score unification + identity bridge |
| [`erd_essential_skills.mmd`](erd_essential_skills.mmd) | Essential skills pipeline (skill_plan → targets) |

## Full ERD (Overview)

| File | Format |
|------|--------|
| [`erd.mmd`](erd.mmd) | Full Mermaid ERD with all 49 entities (best viewed in interactive-erd.html) |

## Dependency Tree

[`dependency_tree.md`](dependency_tree.md) — ASCII art showing the full dependency chain for all 3 primary views.
