<div align="center">

<img src="docs/banner.svg" alt="StudyPlanner: plan, focus, revise, repeat" width="900" />

<br />

**One installable app for the whole study day.**
Timetable, Pomodoro, flashcards, attendance, CGPA and an AI tutor, all offline-ready.

<br />

[**Open the app**](https://midhun-creator.github.io/studyplanner/) &nbsp;·&nbsp; [A study day](#a-study-day-in-order) &nbsp;·&nbsp; [Under the hood](#under-the-hood) &nbsp;·&nbsp; [Run it](#run-it-yourself) &nbsp;·&nbsp; [Roadmap](#roadmap)

<br />

`13 tables` &nbsp;·&nbsp; `every one behind RLS` &nbsp;·&nbsp; `12 unit tests` &nbsp;·&nbsp; `0 build steps` &nbsp;·&nbsp; `works offline`

</div>

<br />

## A study day, in order

Most planners are a pile of features. StudyPlanner is arranged the way a student's day actually runs.

**07:30 &nbsp; Check in**
The dashboard shows your streak, task progress, reminders that are due, and how many days are left to the next exam.

**09:00 &nbsp; Focus**
A Pomodoro timer with study, short-break and long-break modes. It runs on the wall clock, so a background tab never drifts. Log the session against a subject when you finish.

**11:00 &nbsp; Capture**
Tagged, searchable notes. Semester notes sit next to the PDFs your admins publish for each subject.

**14:00 &nbsp; Revise**
Build flashcards per subject and flip through the deck.

**16:00 &nbsp; Ask**
Stuck? Ask the Gemini-powered tutor, or send a study request to your admin for materials or a timetable and get the reply inside the app.

**18:00 &nbsp; Track**
Study-time breakdowns, per-subject attendance calendars, and semester marks with CGPA trends in Chart.js.

**21:00 &nbsp; Plan tomorrow**
Add exams to the timetable, set one-off or recurring reminders, and tick off tasks. Export your data as CSV any time.

> **For admins:** student reports and analytics, PDF uploads per semester, attendance overview, user management, and a queue of study requests to answer.

<br />

## Under the hood

No framework and no bundler. Open `index.html` and it runs.

```
   Browser (vanilla JS, installable PWA)
   ┌───────────────────────────────────────────────┐
   │  index.html · style.css · app.js · utils.js   │
   │  Service worker: offline shell + cached CDN   │
   └───────┬───────────────────────────┬───────────┘
           │ supabase-js               │ chat
           ▼                           ▼
   ┌──────────────────────┐    ┌───────────────────┐
   │ Supabase             │    │ Edge Function     │
   │  Auth (email, Google)│    │  gemini-proxy     │──▶ Gemini
   │  Postgres + RLS      │    │  key stays here   │
   │  Storage (pdfs)      │    └───────────────────┘
   └──────────────────────┘
```

| Piece | Choice |
|---|---|
| UI | HTML, CSS, vanilla JavaScript (ES2020) |
| Data and auth | Supabase |
| Charts | Chart.js 4.4 |
| AI | Gemini, called only through the Edge Function |
| Hosting | GitHub Pages, deployed by Actions |

### Security, plainly

- **The database is the lock, not the UI.** Hiding a button is cosmetic. Every table has Row Level Security: students touch only their own rows.
- **Admin is a server-side claim.** The role lives in `app_metadata`, which users cannot edit, and no admin email is shipped in the source.
- **Students cannot forge admin replies.** Only an admin can write a response to a study request.
- **User text is rendered with `textContent`**, never raw `innerHTML`.
- **The Gemini key never reaches the browser.**
- The Supabase publishable key in `app.js` is public by design. RLS is what protects the data.
- Known gap: the CSP still allows inline handlers. It is on the roadmap.

<br />

## Run it yourself

<details>
<summary><b>1 · Set up Supabase</b></summary>

<br />

1. Create a free [Supabase](https://supabase.com) project.
2. Put its URL and publishable key in `CONFIG` at the top of `app.js`.
3. Run [`supabase/schema.sql`](supabase/schema.sql) in the SQL Editor. It creates the tables, the `pdfs` bucket and all RLS policies.
4. Under **Authentication → Providers**, enable Email and Google, and turn on **Confirm email**.
5. Add your site URL to the allowed redirect URLs.

</details>

<details>
<summary><b>2 · Make yourself admin</b></summary>

<br />

Sign up normally, then run in the SQL Editor:

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"isAdmin": true}'
where email = 'you@example.com';
```

Sign out and back in.

</details>

<details>
<summary><b>3 · Turn on the AI tutor (optional)</b></summary>

<br />

```bash
supabase functions deploy gemini-proxy
supabase secrets set GEMINI_API_KEY=<your-key>
```

Get a key at [Google AI Studio](https://aistudio.google.com/apikey).

</details>

<details>
<summary><b>4 · Start it and test it</b></summary>

<br />

```bash
git clone https://github.com/midhun-creator/studyplanner.git
cd studyplanner
python3 -m http.server 8000      # or: npx serve .
```

Open http://localhost:8000, then:

```bash
npm test          # 12 unit tests, Node 18+
npm run check     # syntax check
```

Deploys happen on every push to `main`. Enable **Settings → Pages → Source: GitHub Actions** once.

</details>

<details>
<summary><b>Keyboard shortcuts</b></summary>

<br />

Student view only, and not while typing.

| Keys | Action | Keys | Action |
|---|---|---|---|
| `Alt` `D` | Dashboard | `Alt` `P` | Pomodoro |
| `Alt` `T` | Timetable | `Alt` `K` | Tasks |
| `Alt` `R` | Reminders | `Alt` `C` | Chatbot |
| `Alt` `N` | Notes | | |

Deep links work too: `index.html#pomodoro`, `#tasks`, and the other section names.

</details>

<details>
<summary><b>Project layout</b></summary>

<br />

```
index.html   app shell and screens        sw.js          service worker
style.css    themes and components        manifest.json  PWA manifest
app.js       application logic            supabase/      schema and RLS
utils.js     pure helpers, unit-tested    tests/         node:test suite
icons/       PWA and social images        docs/          banner, project abstract
```

</details>

<br />

## Roadmap

- [ ] Split `app.js` into ES modules
- [ ] Replace inline `onclick` handlers, then drop `'unsafe-inline'` from the CSP
- [ ] Integration tests for the Supabase flows
- [ ] Push notifications for reminders
- [ ] CSV and PDF export of study analytics
- [ ] Internationalisation

<br />

## Where it came from

A minor project from the Department of Computer Hardware Engineering, Government Polytechnic College, Palakkad. Read the [original abstract](docs/project-abstract.pdf).

Built by Sajeeshna M, Maya P.M and Binnya D. Maintained by [Midhu](https://github.com/midhun-creator).

<div align="center">

<br />

[MIT License](LICENSE) &nbsp;·&nbsp; [Contributing](CONTRIBUTING.md) &nbsp;·&nbsp; [Changelog](CHANGELOG.md) &nbsp;·&nbsp; [Report a bug](https://github.com/midhun-creator/studyplanner/issues/new?template=bug_report.md)

</div>
