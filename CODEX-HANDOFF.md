# Together publication handoff

## Publication continuation — October 26, 2026
- Dedicated public repository: https://github.com/tylersahagun/together-training
- Deployment URL: https://tylersahagun.github.io/together-training/
- Pages source: `gh-pages` branch, repository root. The publishing pull request targets `main`; it is not necessary to merge it for Pages to serve the site.
- Application source and the standalone preview are preserved from the original package.
- Run `node --check app.js`, `node --check data.js`, and `node verify.cjs`. Browser checks should also cover both profiles, reload persistence, set validation/completion, notes, timers, all twelve playable guides, search, history/edit, JSON round-trip with newer-edit preservation, CSV export, and the 390px phone layout.
- Logs remain device-local. No backend or automatic cross-device sync has been added.
- The original handoff below records the pre-publication package state and is retained for context; its deployment status is historical.

# Original handoff: Continue Together in Codex

## Goal
Finish and publish this existing training tracker on GitHub Pages for Tyler and Maddie. Preserve the existing design and week-one plan.

## Current state
- Complete plain HTML/CSS/JavaScript implementation. No framework or build dependencies.
- Seven-day beginner plan; three lifting days, three cardio days, one recovery day.
- Twelve exercise guides with original vector movement sketches, playback, technique instructions and external coaching references.
- Separate Tyler and Maddie profiles; weights, reps/seconds, two working sets, variants, notes, completion, cardio minutes and effort.
- Rest timer, guided walking intervals, date-based history, adjustable week start, JSON export/import and CSV export.
- Logs currently use browser localStorage. No authentication or automatic syncing across phones. Do not promise shared/cross-device persistence unless a backend is implemented.
- Code has NOT been pushed to GitHub and the site is NOT published.

## Validation already done
- JavaScript syntax checks passed.
- Browser checks covered independent profiles, persistence after reload, set validation, lifting completion, cardio completion, rest/interval timers, movement playback, search, and a 390px phone-width iframe.
- Focused checks in verify.cjs cover dates, backup validation, text escaping, CSV formula protection, interval length and all sketches. Run node verify.cjs from the unzipped root.
- Last test cleanup in the temporary browser was interrupted; any remaining entries there are disposable test data. No exercise logs are included in these source files.

## Deployment
- GitHub account: tylersahagun.
- Preferred new dedicated repository: together-training (check availability first).
- Existing tylersahagun/tylersahagun.github.io is PRIVATE, contains a separate Next.js portfolio, and reported has_pages=false. Do not change its visibility or publish its unrelated contents.
- The GitHub connector could edit existing repositories but did not provide create-repository or Pages-settings tools.
- Browser sign-in was attempted via Google but did not complete; the secure sign-in request timed out. No credentials or tokens are in the package.
- In a locally authenticated Codex environment, use GitHub CLI or the user's normal authorized Git workflow to create the dedicated repository, push the static files and enable GitHub Pages. A public source repository is suitable for the published tracker; workout logs must stay out of Git. If account settings require approval, present the exact blocker.
- Verify the actual published URL and mobile behavior before reporting success.

## File layout
- index.html, style.css, data.js, app.js: actual site, at repository root.
- .nojekyll: disables Jekyll processing.
- standalone/together-training.html: self-contained preview copy; regenerate after changing source files.
- README.md: behavior, sources and deployment guidance.
- verify.cjs: targeted verification script.

## User context
Both are beginners or returning after a break, can exercise 45–60 minutes, and reported no current exercise limitations. Equipment: squat rack, bench, pull-up/dip bars, EZ/straight bars, pairs of plates 5–45 lb and treadmill. Plan keeps about three repetitions in reserve and substitutes controlled walking for maximal intervals. No supplements, sauna/cold protocol or loaded neck work.

## First next steps
1. Read README.md and inspect the existing implementation; do not rebuild from scratch.
2. Run node verify.cjs and syntax checks; preview it locally.
3. Finish a dedicated GitHub repository and Pages deployment using available authenticated tooling.
4. Return the verified live URL and explain that current logs are device-local.
