---
name: weekly-workout-scheduler
description: Plan a training week or translate a user-specified week into a WorkoutSync import using the project's Huberman and golf rules.
---

Read `data/huberman_rules.json` and `planner/README.md`. In prescribed mode use the user's stated workouts; flag conflicts rather than silently changing them. In autonomous mode collect current goals, equipment, availability, recent training, limitations, and recovery before prescribing. Never infer physiological baselines or invent measured zones or 1RM. Apply readiness, spacing, session duration, recovery and downshift rules, identify uncertainty and any unmet rule or equipment limitations; do not describe an unverified claim as fact. Match existing exercises and experience before adding intensity. Check Apple activity and alert support at import. Ask for the week and dates when absent. Produce the documented JSON outside the repository, run `python3 planner/validate.py` on it, and report unresolved exceptions. The phone app requires an explicit preview and sync action; it does not silently schedule workouts.
