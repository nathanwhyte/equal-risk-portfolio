# Repository Guidelines

## Project Structure & Module Organization
- `app/` holds Rails code; controllers/models encapsulate domain logic, views render UI, and `javascript/controllers` stores Stimulus controllers.
- `app/assets` contains Tailwind entrypoints; compiled output lives in `app/assets/builds` and is ignored from source edits.
- `config/` manages environment settings, routes, and credentials; update `config/routes.rb` alongside new controllers.
- `db/` tracks schema and seeds; migrations belong in `db/migrate` and should be reversible.
- `test/` mirrors app structure with Minitest suites plus fixtures under `test/fixtures` for repeatable data.

## Build, Test, and Development Commands
- `bin/setup` installs Ruby gems, runs `bun install`, prepares the database, and can boot the dev server.
- `bin/dev` runs Foreman with `bin/rails server`, plus Bun watchers for JS (`bun run build --watch`) and CSS (`bun run build:css --watch`).
- `bin/rails db:prepare` syncs schema and seeds; rerun after pulling migrations.
- `bun run build` and `bun run build:css` compile production-ready JS and Tailwind assets.

## Coding Style & Naming Conventions
- Ruby follows the Omakase Rubocop profile with two-space indentation, `snake_case` methods, and `CamelCase` classes.
- Front-end code is formatted with Prettier (Tailwind and Ruby plugins); run `bin/fmt` before committing for consistent ordering and lint fixes.
- Stimulus controllers live under `app/javascript/controllers` and use `<feature>_controller.js`; data attributes mirror controller names (e.g., `data-controller="stocks"`).

## Testing Guidelines
- Execute `bin/rails test` for the full suite; the harness parallelizes workers via `test/test_helper.rb`.
- Use `bin/rails test:system` for Capybara-driven browser flows kept in `test/system`.
- Name unit and integration files `<subject>_test.rb`; add fixtures or factories to keep scenarios deterministic.
- New endpoints or UI changes should include controller, model, or system coverage so regressions trip CI early.

## Commit & Pull Request Guidelines
- Structure commit subjects in the imperative mood, optionally prefixed with issue tags like `[TWS-38]` observed in history.
- Group related changes per commit; include schema dumps or lockfiles when tooling updates them.
- PRs must populate the template in `.github/pull_request_template.md`, tick the testing checklist, and link issues or tickets.
- Attach screenshots or recordings for UI-visible updates and note any manual steps reviewers must perform.

## Security & Maintenance Checks
- Run `bin/brakeman` before large merges to surface Rails security warnings.
- Use `bin/rubocop` (or the combined `bin/fmt`) to resolve lint violations prior to review.
- Review `config/credentials` usage and avoid committing secrets; prefer ENV-backed configuration when extending settings.
