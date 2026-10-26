# Together — Week One

A mobile-friendly exercise plan and workout log for Tyler and Maddie. Built as plain HTML, CSS and JavaScript for GitHub Pages. No backend, build tools, dependencies, passwords or API keys are needed.

## Included

- Seven-day introductory plan adapted from Huberman's foundational fitness template.
- Twelve exercise guides with original animated movement sketches, technique cues, beginner alternatives and external coaching references.
- Independent Tyler and Maddie profiles; two working sets, weight, repetitions/seconds, completion, notes, warm-up and cardio tracking.
- Date-based session history, adjustable week start, rest timer and guided 22-minute walking intervals.
- JSON backup/import with validation and merge-by-edit-time; CSV export for the selected profile.

## Deployment

Site: https://tylersahagun.github.io/together-training/

Repository: https://github.com/tylersahagun/together-training

GitHub Pages serves the `gh-pages` branch from `/(root)`. The existing application files and standalone preview are preserved. The publishing pull request targets `main`; Pages can serve `gh-pages` before that pull request is merged. Future publishing changes should be committed and pushed to `gh-pages`, followed by checking the Pages deployment and live site.

Workout logs and downloaded backups are never part of the deployment. Each browser stores its own logs; export/import is the way to transfer them between devices.

## Publish a separate copy on GitHub Pages

Create a dedicated repository, for example `together-training`. A public repository works with GitHub Free; private repository Pages hosting requires a supporting GitHub plan. Keep existing unrelated private repositories private.

Upload `index.html`, `style.css`, `data.js`, `app.js` and `.nojekyll` into the repository root, commit to `main`, then open **Settings → Pages**. Under **Build and deployment**, choose **Deploy from a branch**, select `main` and `/(root)`, and save. GitHub displays the published URL after the Pages deployment succeeds. Do not claim the site is live before that deployment completes.

For integration into an existing static-export Next.js site, place the four application files in `public/training/`. The existing Next.js export should copy those static files to `out/training/`. Check repository rules and verify the exported artifact before deploying. Enabling Pages for an existing private site can publish all of its exported pages, so use a dedicated repository if only this tracker should be published.

## Local use

Open `standalone/together-training.html` directly, or serve the main folder with a static web server. Browser storage for local HTML files varies by browser; if storage is unavailable, a visible warning asks you to download a backup before leaving.

## Logs and privacy

Logs live under the localStorage key `together-training:v1`, on the current origin and browser. Profiles are convenience selectors, not authenticated accounts. Logs are not committed to GitHub or transmitted to a server. The same browser/device can switch between both people; different phones do not automatically sync. Export a backup and import it on the other device to combine records. Clearing site data removes the local logs.

Import keeps existing records unless the imported version of that same person's dated session was edited more recently. Deletions do not sync through backups. The UI reports storage failures; export your work before leaving if that warning appears.

Font styling requests Google Fonts; the interface falls back to system fonts if it is unavailable. Exercise coaching links open external websites only when selected.

## Plan and references

Original template: https://www.hubermanlab.com/newsletter/foundational-fitness-protocol

Technique references are linked per exercise in `data.js`: CSCCa, Catalyst Athletics, NHS and ACE. Sketches are original simplified teaching aids, not motion-capture demonstrations or form assessments. Some linked demos show the standard exercise, and the site explicitly explains the beginner variation.

This is an introductory general-fitness plan: two working sets, roughly three repetitions in reserve, and walking in place of maximal intervals. No deliberate heat/cold exposure or loaded neck training is prescribed.

## Verification

`node --check app.js` and `node --check data.js` check syntax. `node verify.cjs` runs focused checks for dates, backup validation, escaping, CSV formula protection, interval duration and all twelve sketches. Browser checks cover profile isolation, persistence after reload, set validation, completion, cardio logging, timers, search, example playback and the phone-width layout.
