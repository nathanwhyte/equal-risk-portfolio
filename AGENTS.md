# Repository Guidelines

This repository is a monorepo containing a Rails frontend and a Python backend API for financial portfolio analysis.

## Prerequisites

- **Ruby**: Version specified in `.ruby-version` (Rails 8.0+)
- **Python**: 3.13+ (for the Python API)
- **Node.js**: Bun is used for JavaScript tooling
- **Database**: PostgreSQL
- **Package Managers**: `bundler` (Ruby), `bun` (JavaScript), `uv` (Python)

## Quick Setup

1. **Install system dependencies**: Ruby, Python 3.13+, Bun, PostgreSQL
2. **Run setup script**: `bin/setup`
3. **Install pre-commit hooks**: `pre-commit install`
4. **Set up Python API dependencies**: `uv pip sync api/uv.lock`

## Essential Commands

### Development
- `bin/dev` - Run Rails server with asset watchers
- `bin/rails server` - Run Rails server only
- `bin/rails console` - Open Rails console
- `bin/fmt` - Format all code (run before committing)
- `bin/rails test` - Run all tests
- `bin/rails test:system` - Run system tests

### Python API
- `uvicorn app.main:app --reload --app-dir api` - Run FastAPI server locally
- `python api/scripts/seed.py` - Run seed script

## Detailed Guidelines

For comprehensive development guidelines, coding standards, testing requirements, and workflow rules, see **`.cursor/rules/project-guidelines.mdc`**.

**Note**: If `.cursor/rules/project-guidelines.mdc` does not exist, generate it based on the content from this repository's development guidelines. The rules file provides optional context for Cursor AI assistance.
