# Repository Guidelines

This document provides guidelines for developing, testing, and contributing to this repository. It covers both the Ruby on Rails application and the Python financial analysis API.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure & Module Organization](#project-structure--module-organization)
- [Development Environment & Commands](#development-environment--commands)
- [Coding Style & Naming Conventions](#coding-style--naming-conventions)
- [Git Hooks & Pre-commit](#git-hooks--pre-commit)
- [Testing Guidelines](#testing-guidelines)
- [Commit & Pull Request Guidelines](#commit--pull-request-guidelines)
- [Deployment](#deployment)
- [Security & Maintenance](#security--maintenance)

## Prerequisites

### System Requirements

-   **Ruby**: Version specified in `.ruby-version` (Rails 8.0+)
-   **Python**: 3.13+ (for the Python API)
-   **Node.js**: Bun is used for JavaScript tooling
-   **Database**: PostgreSQL
-   **Package Managers**:
    -   `bundler` for Ruby gems
    -   `bun` for JavaScript dependencies
    -   `uv` for Python dependencies

### External Services

-   **Polygon.io**: Used for fetching stock market data (API key required)
-   **AWS Lambda** (optional): For serverless API deployment

## Project Structure & Module Organization

The repository is a monorepo containing a Rails frontend and a Python backend API.

### Ruby on Rails App (`app/`)

-   **`app/`**: Holds all Rails application code.
    -   `controllers`/`models`: Encapsulate core domain logic.
        -   `concerns/call_lambda.rb`: Helper module for invoking the Python API
    -   `views`: Render UI components and pages (using ERB templates).
    -   `javascript/controllers`: Contains Stimulus controllers for front-end interactivity.
-   **`app/assets`**: Contains Tailwind CSS entrypoints. Compiled output lives in `app/assets/builds` and should not be edited directly.
-   **`config/`**: Manages environment settings, routes, and credentials.
    -   Update `config/routes.rb` when adding new controllers or endpoints.
    -   `config/initializers/lambda.rb`: Configures AWS Lambda client for API calls.
    -   `config/deploy.yml`: Kamal deployment configuration.
-   **`db/`**: Tracks database schema and seeds. Migrations belong in `db/migrate` and should be reversible.
    -   Uses PostgreSQL with `pg_crypto` extension enabled.
    -   Solid* adapters (`solid_cache`, `solid_queue`, `solid_cable`) for caching, background jobs, and Action Cable.
-   **`test/`**: Mirrors the `app` structure with Minitest suites. Fixtures for test data are located under `test/fixtures`.
-   **`bin/`**: Contains useful development and deployment scripts (see [Development Commands](#development-environment--commands)).

### Front-end Stack

-   **Hotwire**: Turbo + Stimulus for building modern, fast web applications without much JavaScript.
    -   **Turbo Rails**: SPA-like navigation and partial page updates.
    -   **Stimulus**: Modest JavaScript framework for adding interactivity.
-   **Tailwind CSS 4**: Utility-first CSS framework.
-   **DaisyUI**: Component library built on Tailwind CSS.
-   **Propshaft**: Modern asset pipeline for Rails.

### Python API (`api/`)

-   **`api/`**: Contains the Python-based financial calculation API.
    -   **`api/app`**: The main application module, built with FastAPI.
        -   `main.py`: The main entry point, defining API endpoints.
        -   `db.py`: Handles database connections and interactions (SQLAlchemy + PostgreSQL).
        -   `fetch.py`: Logic for fetching data from external sources (Polygon.io).
        -   `math.py`: Contains the core financial calculations (NumPy, SciPy, Pandas).
    -   **`api/pyproject.toml`**: Defines project metadata and dependencies, managed with `uv`.
    -   **`api/scripts/`**: Utility scripts (e.g., `seed.py` for seeding the database).
    -   **Key Dependencies**:
        -   `fastapi[standard]`: API framework
        -   `mangum`: AWS Lambda adapter for FastAPI
        -   `pandas`, `numpy`, `scipy`: Financial calculations
        -   `polygon-api-client`: Market data fetching
        -   `psycopg2-binary`, `sqlalchemy`: Database access

### Architecture

The Rails application serves the web UI and communicates with the Python API for complex financial calculations. The Python API can be invoked either:

1. **Directly** via HTTP (local development, `uvicorn`)
2. **Via AWS Lambda** (production, using `mangum` adapter)

## Development Environment & Commands

### Initial Setup

1. **Install system dependencies**: Ruby, Python 3.13+, Bun, PostgreSQL
2. **Run setup script**:
    ```bash
    bin/setup
    ```
    This installs Ruby gems, Bun dependencies, prepares the database, and optionally boots the dev server.

3. **Install pre-commit hooks**:
    ```bash
    pre-commit install
    ```

4. **Set up Python API dependencies**:
    ```bash
    uv pip sync api/uv.lock
    ```

### Ruby on Rails Commands

-   **`bin/dev`**: Runs the Rails server (with debugging enabled) and Bun watchers for JS and CSS using Foreman.
    -   Starts three processes: `web` (Rails), `js` (JavaScript bundler), `css` (Tailwind compiler)
-   **`bin/rails server`**: Run Rails server only (without asset watchers).
-   **`bin/rails db:prepare`**: Syncs the database schema and seeds. Run this after pulling new migrations.
-   **`bin/rails console`**: Opens an interactive Rails console.
-   **`bin/rails routes`**: Lists all defined routes.
-   **`bun run build`**: Compile production-ready JavaScript bundle.
-   **`bun run build:css`**: Compile production-ready Tailwind CSS.
-   **`bin/jobs`**: Run background job processor (Solid Queue).

### Python API Commands

-   **Install dependencies**:
    ```bash
    uv pip sync api/uv.lock
    ```
-   **Run the FastAPI server locally** (with auto-reload):
    ```bash
    uvicorn app.main:app --reload --app-dir api
    ```
-   **Run seed script**:
    ```bash
    python api/scripts/seed.py
    ```

### Useful Development Scripts

-   **`bin/fmt`**: Formats all code (Ruby, ERB, JavaScript, CSS) for consistency. Runs:
    -   `erb-format` for ERB templates
    -   `tailwindcss-format` for Tailwind class ordering
    -   `rubocop -A` for Ruby auto-corrections
-   **`bin/rubocop`**: Lints Ruby code with RuboCop.
-   **`bin/brakeman`**: Checks for Rails security vulnerabilities.
-   **`bin/kamal`**: Manages Kamal deployments.
-   **`bin/thrust`**: HTTP/2 proxy for local development (Thruster).

## Coding Style & Naming Conventions

### Ruby

-   **Style Guide**: Follows the **Omakase Rubocop** profile (Rails community conventions).
-   **Indentation**: Two spaces (no tabs).
-   **Naming**:
    -   `snake_case` for methods, variables, and file names
    -   `CamelCase` for classes and modules
    -   `SCREAMING_SNAKE_CASE` for constants
-   **Linter**: RuboCop with `rubocop-rails-omakase` gem.
-   **Auto-fix**: `bin/rubocop -A` or `bin/fmt`

### Python

-   **Formatter**: Ruff (included in `dev` dependencies in `pyproject.toml`).
-   **Conventions**: PEP 8 style guide.
-   **Type Hints**: Encouraged but not required.

### Front-end (JavaScript/CSS/ERB)

-   **JavaScript**: Modern ES6+ syntax, formatted with Prettier.
-   **CSS**: Tailwind utility classes, ordered with `tailwindcss-format`.
-   **ERB Templates**: Formatted with `erb-format`.
-   **Prettier Config**: `.prettierrc.json` with `prettier-plugin-tailwindcss` for consistent class ordering.

### Formatting Workflow

Run **`bin/fmt`** before committing to ensure all files are properly formatted. This command runs:

1. `erb-format --write app/views/**/*.*.erb`
2. `tailwindcss-format app/**/*.*.erb -w`
3. `bin/rubocop -A`

## Git Hooks & Pre-commit

This repository uses `pre-commit` to enforce code quality and consistency before commits and pushes.

### Setup

Install pre-commit hooks:

```bash
pre-commit install
```

### Pre-commit Stage (Before Each Commit)

Runs automatically before commits. Checks include:

-   **Trailing whitespace removal** (`trailing-whitespace`)
-   **End-of-file fixer** (`end-of-file-fixer`)
-   **YAML validation** (`check-yaml`)
-   **Large file detection** (`check-added-large-files`)
-   **Rails checks** (`bin/precommit`):
    -   Runs `bin/fmt` to format all code
    -   _Note: Tests are currently disabled during pre-commit (see TODO in script)_

### Pre-push Stage (Before Each Push)

Runs automatically before pushing to remote. Executes `bin/prepush`, which:

-   Prepares the test database (`bin/rails db:test:prepare`)
-   Runs the full test suite (`bin/rails test`)
-   Runs system tests (`bin/rails test:system`)

### Manual Execution

Run hooks manually anytime:

```bash
pre-commit run --all-files        # Run pre-commit hooks
pre-commit run --hook-stage pre-push --all-files  # Run pre-push hooks
```

## Testing Guidelines

### Test Structure

-   **`test/`**: Contains all tests, organized to mirror the `app/` structure.
    -   `controllers/`: Controller tests
    -   `models/`: Model tests
    -   `system/`: End-to-end browser tests (Capybara + Selenium)
    -   `fixtures/`: Test data fixtures (YAML files)
    -   `test_helper.rb`: Shared test configuration

### Running Tests

-   **Run all tests**:
    ```bash
    bin/rails test
    ```
-   **Run system tests only** (browser-based, Capybara):
    ```bash
    bin/rails test:system
    ```
-   **Run a specific test file**:
    ```bash
    bin/rails test test/controllers/portfolios_controller_test.rb
    ```
-   **Run a specific test case**:
    ```bash
    bin/rails test test/controllers/portfolios_controller_test.rb:10
    ```

### Writing Tests

-   **Naming Convention**: Test files should be named `<subject>_test.rb`.
-   **Test Framework**: Minitest (Rails default).
-   **System Tests**: Use Capybara for browser automation, Selenium WebDriver for browser control.
-   **Coverage Requirements**: New features, endpoints, or UI changes should include:
    -   **Controller tests**: For new endpoints or controller actions
    -   **Model tests**: For new models or business logic
    -   **System tests**: For critical user flows and UI interactions

## Commit & Pull Request Guidelines

### Commit Messages

-   **Format**: Use the imperative mood (e.g., "Add user authentication", not "Added" or "Adds").
-   **Prefix** (optional): Include issue/ticket tags like `[TWS-38]` at the start.
-   **Examples**:
    -   `"Add portfolio creation feature"`
    -   `"[TWS-65] Refactor ticker search controller"`
    -   `"Fix CORS issue in Python API"`

### Commits

-   **Scope**: Group related changes into a single logical commit.
-   **Database Changes**: Include `db/schema.rb` in the same commit as migrations.
-   **Dependencies**: Include lockfile updates (`Gemfile.lock`, `bun.lock`, `uv.lock`) with the dependency change commit.
-   **Formatting**: Don't mix formatting changes with logic changes. Commit them separately.

### Pull Requests

-   **Template**: Fill out `.github/pull_request_template.md` (if it exists).
-   **Testing Checklist**:
    -   [ ] Tests added/updated for new features
    -   [ ] All tests passing (`bin/rails test` and `bin/rails test:system`)
    -   [ ] Code formatted (`bin/fmt`)
    -   [ ] No security issues (`bin/brakeman` for large changes)
-   **Documentation**:
    -   Link to relevant issues or tickets
    -   Explain **why** the change was made, not just **what** changed
    -   Include screenshots or recordings for UI changes
-   **Review**: Request review from team members before merging.

## Deployment

This application uses **Kamal** for deployment, configured in `config/deploy.yml`.

### Kamal Deployment

Kamal deploys Docker containers to remote servers with zero-downtime deployments.

-   **Deploy**:
    ```bash
    bin/kamal deploy
    ```
-   **View logs**:
    ```bash
    bin/kamal logs
    # or use the alias:
    bin/kamal app logs -f
    ```
-   **Open console on server**:
    ```bash
    bin/kamal console
    # or:
    bin/kamal app exec --interactive --reuse "bin/rails console"
    ```
-   **Database console**:
    ```bash
    bin/kamal dbc
    ```
-   **SSH into server**:
    ```bash
    bin/kamal shell
    # or:
    bin/kamal app exec --interactive --reuse "bash"
    ```

### Configuration

-   **Server details**: Configured in `config/deploy.yml`
-   **Secrets**: Stored in `.kamal/secrets` (not committed to version control)
-   **Environment Variables**:
    -   `RAILS_MASTER_KEY`: Required for decrypting credentials
    -   `KAMAL_REGISTRY_PASSWORD`: For Docker registry authentication
-   **Proxy**: SSL enabled via Let's Encrypt (configured in `deploy.yml`)

### Python API Deployment

The Python API is designed to be deployed as an AWS Lambda function:

1. Package the API with dependencies
2. Deploy using AWS SAM, Serverless Framework, or direct Lambda deployment
3. Configure the Lambda function URL or API Gateway endpoint
4. Update Rails environment variables to point to the Lambda endpoint

Alternatively, for development or alternative deployments:

-   Run FastAPI with `uvicorn` in a container
-   Use the same Dockerfile approach as the Rails app

## Security & Maintenance

### Security Tools

-   **Brakeman**: Static analysis for Rails security vulnerabilities
    ```bash
    bin/brakeman
    ```
    Run this before large merges or periodically to catch security issues.

### Code Quality

-   **RuboCop**: Ruby linter and formatter
    ```bash
    bin/rubocop          # Check for issues
    bin/rubocop -A       # Auto-fix issues
    bin/fmt              # Comprehensive formatting (includes RuboCop)
    ```

### Credentials & Secrets

-   **Rails Credentials**: Stored encrypted in `config/credentials.yml.enc`
    -   Edit: `bin/rails credentials:edit`
    -   Never commit `config/master.key` or `.kamal/secrets`
-   **Python API**: Use environment variables for secrets (AWS credentials, database passwords, API keys)
-   **Local Development**: Create `.env` file for local secrets (add to `.gitignore`)

### Dependencies

-   **Ruby Gems**: Keep updated with `bundle update`
-   **JavaScript**: Update with `bun update`
-   **Python**: Update with `uv pip compile` and `uv pip sync`
-   **Security Audits**:
    -   Ruby: `bundle audit` (if gem is installed)
    -   JavaScript: `bun audit`

### Database Maintenance

-   **Migrations**: Always test migrations on a copy of production data
-   **Backups**: Ensure regular database backups are configured
-   **Rollbacks**: Write reversible migrations (`up`/`down` or `change` with reversible commands)
