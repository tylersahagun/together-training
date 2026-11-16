# Workout scheduling

For requests to plan or schedule a week, use `.codex/skills/weekly-workout-scheduler/SKILL.md` and read `data/huberman_rules.json`. Treat the rules as planning inputs, not verified medical facts. Preserve user-provided plans, identify conflicts, and never invent personal baselines. Confirm the user's requested location for an export; keep personal plans out of Git. Validate payloads with `python3 planner/validate.py PATH` before import. Follow the repository's GitHub workflow and retain existing tracker behavior.
