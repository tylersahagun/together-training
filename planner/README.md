# Weekly plan interchange, version 1

The source rules in `data/huberman_rules.json` are unverified planning guidance, including golf-specific adaptations; they are not a substitute for current individual context. No personal baselines are included in the repository. Request them before autonomous training prescription. Record conflicting or unfulfilled rules for the user to review; the validator below checks interchange structure and selected safety constraints, not complete clinical or protocol compliance.

Save a UTF-8 JSON file to iCloud Drive and use the iPhone app's Files picker. Required format:

```json
{"version":1,"weekStart":"2026-11-16","workouts":[{"id":"dd3e8760-f455-4a26-a66c-c0e2c1455c00","date":"2026-11-16","title":"Example","activity":"running","location":"outdoor","kind":"custom","steps":[{"purpose":"work","name":"Easy","goal":"time","seconds":1200},{"purpose":"cooldown","name":"Slow breathing","goal":"time","seconds":180}]}]}
```

`activity`: running, walking, traditionalStrengthTraining, functionalStrengthTraining, mindAndBody, golf. `location`: indoor, outdoor, unknown. `kind`: custom or single. A single workout has exactly one step with an open or time goal. Custom steps have `purpose`: warmup, work, recovery, cooldown. Goals are `open` or `time`; time requires positive `seconds`. Optional `heartRateZone` is 1–5 and uses the Watch's configured zones. Each workout has a stable UUID, unique within the week; use a new ID for changed content. The date is a local calendar day. WorkoutKit schedules by calendar day, not a guaranteed start time. An imported week is checked for unsupported activity/goal/alert combinations before scheduling. Golf single-goal workouts cannot carry named segmented cooldowns; provide breathing guidance separately. A native Watch may present or advance steps differently depending on system settings.

`python3 planner/validate.py path/to/week.json` checks the payload and emits errors. It does not create prescriptions, read Health data, infer zones, or prove recovery spacing from unknown prior weeks. Workouts not fully validated by the iOS app cannot be scheduled.
