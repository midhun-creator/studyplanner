# Changelog

## 2.2.0

### Security
- Admin role now comes from `app_metadata.isAdmin`, which only the server can write.
  The admin email was removed from the public source. `is_admin()` in
  `supabase/schema.sql` reads the same claim.
- **Upgrade note:** existing admins must be re-granted once with the SQL in `supabase/schema.sql`.

### Docs
- New README, social preview image, and a `scripts/publish.sh` helper.
- Replaced `YOUR_USERNAME` placeholders in the canonical URL, sitemap and robots.txt.

## 2.1.0

### Fixed
- **Timezone:** streaks, study time, attendance and reminders used UTC dates.
  They now use local dates (`localDateStr`, `daysUntil`).
- **Reminders:** "days left" was off by one in UTC+ timezones.
- **Study requests:** admin answers never reached students.
  Two incompatible flows existed. Both sides now use `study_requests.response_text`.
- **Stored XSS:** admin/student text is now rendered with `textContent`.
  The `innerHTML` option was removed from the `el()` helper.
- **Admin response button:** no longer relies on the global `event` object.
- **Pomodoro:** timer uses the wall clock, so background tabs no longer drift.
- **Service worker:** app shell is network-first, so updates ship immediately.
  CDN scripts and fonts are precached, so the app starts offline.
  Supabase traffic is never intercepted.
- **PWA shortcuts:** `#pomodoro` and `#tasks` now open the right section.
- **PWA install:** added 192/512/maskable PNG icons and an Apple touch icon.
- **Dead code:** removed duplicate admin functions, old study-request flow,
  empty key stubs, missing element lookups, and stale comments.
  Sections renumbered 1–32.

### Security
- Admin UI requires a confirmed email address.
- Added `supabase/schema.sql` with Row Level Security for every table and the `pdfs` bucket.
- Tightened the CSP allow-list. Removed `unsafe-eval`.
- Sign-up requires passwords of at least 8 characters.
- OAuth redirect no longer includes the URL hash.

### Added
- `utils.js` with 8 pure helpers, and 12 unit tests (`npm test`).
- CI workflow (syntax check + tests).
- `CHANGELOG.md`.

### Changed
- "CGPA" is now labeled "Average CGPA". It is the mean of per-semester entries.

## 2.0.0
- Initial public release.
