# Contributing

Thanks for your interest in StudyPlanner.

## Workflow

1. Fork the repository.
2. Create a branch: `git checkout -b feat/short-description`.
3. Make focused changes. Follow `.editorconfig`.
4. Run `npm test` and `npm run check`. Test manually in Chrome and Firefox, desktop and mobile widths.
5. Open a pull request describing what changed and why.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `docs:`, `refactor:`, `style:`, `chore:`.

## Code guidelines

- Vanilla JavaScript only. No build step.
- Put pure logic in `utils.js` and add a test in `tests/`.
- Use `textContent`, never `innerHTML`, for user or admin data.
- Use local dates (`localDateStr`, `daysUntil`), never `toISOString()`.
- Build DOM with the `el()` helper.
- Keep sections in `app.js` numbered and labeled.
- Never commit secrets. Gemini keys live in Supabase Edge Function secrets.

## Reporting security issues

Do not open a public issue. Use GitHub's **Security → Report a vulnerability** (private advisory).
