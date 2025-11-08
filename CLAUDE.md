# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **joyinchat v4.6.0**, a customized Chatwoot installation. The main application code is in the `chatwoot/` directory. This is a full-stack customer support platform built with Ruby on Rails backend and Vue 3 frontend.

## Quick Start

```bash
cd chatwoot
bundle install && pnpm install
```

**Environment Setup:**
- Copy `.env.example` to `.env` and configure required variables
- Required services: PostgreSQL, Redis
- Generate SECRET_KEY_BASE: `rake secret`
- For MFA/2FA: `rails db:encryption:init`

**Run Development Server:**
```bash
cd chatwoot
pnpm dev        # or: overmind start -f ./Procfile.dev
```
This starts 3 processes: Rails server (port 3000), Sidekiq worker, and Vite dev server.

**Using Docker:**
```bash
docker-compose up
```

## Build / Test / Lint Commands

All commands should be run from the `chatwoot/` directory unless otherwise noted.

### JavaScript/Vue
- **Lint**: `pnpm eslint` (fix: `pnpm eslint:fix`)
- **Test**: `pnpm test` (watch: `pnpm test:watch`)
- **Test with coverage**: `pnpm test:coverage`
- **Build**: `bin/vite build` (SDK only: `BUILD_MODE=library bin/vite build`)
- **Component stories**: `pnpm story:dev` (build: `pnpm story:build`)

### Ruby/Rails
- **Lint**: `bundle exec rubocop -a`
- **Test all**: `bundle exec rspec`
- **Test file**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Console**: `bundle exec rails console`

### Database
- **Create**: `bundle exec rails db:create`
- **Migrate**: `bundle exec rails db:migrate`
- **Seed**: `bundle exec rails db:seed`
- **Reset**: `bundle exec rails db:reset`
- **Setup Chatwoot**: `bundle exec rails db:chatwoot_prepare`

### Using Makefile
The Makefile provides shortcuts for common tasks:
- `make setup` - Install dependencies
- `make run` - Start overmind (checks if already running)
- `make force_run` - Force restart overmind
- `make db` - Prepare Chatwoot database
- `make console` - Rails console

## Code Style & Guidelines

### Styling - Tailwind Only
**CRITICAL**: This project uses Tailwind CSS exclusively.
- **DO NOT** write custom CSS
- **DO NOT** use scoped CSS in Vue components
- **DO NOT** use inline styles
- **ALWAYS** use Tailwind utility classes
- Colors: Defined in `theme/colors.js` using Radix UI colors
  - Legacy colors: `woot`, `green`, `yellow`, `slate`, `black`, `red`, `violet`
  - New design system: `n.slate`, `n.iris`, `n.blue`, `n.ruby`, `n.amber`, `n.teal`, `n.gray`

### Vue 3 (Frontend)
- **ALWAYS** use Composition API with `<script setup>` at the top of components
- **Components**: PascalCase naming
- **Events**: camelCase naming
- **No bare strings**: Use i18n for all user-facing text
- **PropTypes**: Always define prop types
- **New components**: Use `components-next/` for message bubbles and new design system

### Ruby (Backend)
- Follow RuboCop rules (150 character max line length)
- Use compact `module/class` definitions (avoid nested styles)
- Strong params in controllers
- Validate presence/uniqueness in models, add proper indexes
- Use custom exceptions from `lib/custom_exceptions/`

### General Principles
- **MVP focus**: Minimum code change, happy-path only
- **No defensive programming** unless explicitly needed
- **Remove dead code**: Don't leave unused/unreachable code
- **Single approach**: Don't write multiple versions or backups
- **Don't write specs** unless explicitly requested
- **Break down tasks** into small, testable units
- **Iterate after confirmation**

## Translations (i18n)

- **ONLY update** `en.yml` (backend) and `en.json` (frontend)
- Other languages are managed by the community via Crowdin
- Backend i18n → `config/locales/en.yml`
- Frontend i18n → `app/javascript/.../locale/en.json`

## Architecture Overview

### Backend (Rails API)
- **Pattern**: MVC with service objects, listeners, and background jobs
- **API**: RESTful under `api/v1/` namespace, JSON responses
- **Controllers**: `app/controllers/api/v1/`
- **Models**: `app/models/` (uses PostgreSQL with JSONB for flexible attributes)
- **Services**: `app/services/` (organized by domain)
- **Jobs**: `app/jobs/` (Sidekiq background processing)
- **Listeners**: `app/listeners/` (event-driven architecture)
- **Builders**: `app/builders/` (object construction)
- **Policies**: `app/policies/` (authorization)
- **Finders**: `app/finders/` (query objects)
- **Actions**: `app/actions/` (command pattern)

### Frontend (Vue 3 Multi-App)
The frontend is split into multiple Vue applications:
- `dashboard/` - Main agent dashboard (primary app)
- `v3/` - Authentication/login pages
- `widget/` - Customer-facing chat widget
- `portal/` - Help center portal
- `survey/` - CSAT survey interface
- `superadmin_pages/` - Super admin console
- `sdk/` - JavaScript SDK for embedding

**Tech Stack:**
- Build: Vite + vite-plugin-ruby
- State: Vuex
- Routing: Vue Router
- Real-time: ActionCable (WebSockets)
- Components: Migrating to `components-next/` for new design system

### Key Integrations
- **Authentication**: Devise with token-based auth (devise_token_auth)
- **Background Jobs**: Sidekiq
- **Real-time**: ActionCable over WebSockets
- **Storage**: Active Storage for file uploads
- **Channels**: Email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS
- **Feature Flags**: FlagShihTzu (single-column multi-flag)

### Directory Highlights
- `app/dispatchers/` - Event dispatching
- `app/drops/` - Liquid template drops for emails
- `app/presenters/` - View presentation logic
- `lib/` - Shared libraries and utilities
- `lib/custom_exceptions/` - Custom exception classes
- `enterprise/` - Enterprise edition overlay (see below)

## Enterprise Edition Compatibility

Chatwoot has an **Enterprise overlay** under `enterprise/` that extends/overrides OSS code. When modifying core functionality:

**Checklist for changes impacting core logic or public APIs:**
1. Search for related files in both `app/` and `enterprise/`:
   ```bash
   rg -n "ServiceName|ControllerName|ModelName" app enterprise
   ```
2. Consider if Enterprise needs:
   - An override (e.g., `enterprise/app/...`)
   - An extension point (`prepend_mod_with`, hooks, configuration)
3. Avoid hardcoding instance/plan-specific behavior in OSS
4. Keep request/response contracts stable across OSS and Enterprise
5. When renaming/moving shared code, mirror the change in `enterprise/`
6. Enterprise specs go in `spec/enterprise/`, mirroring OSS layout

Reference: https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

## Theme/Branding Customization

This repository appears to be a customized installation (joyinchat). Theme customizations are in:
- `theme/colors.js` - Color palette definitions
- `theme/icons.js` - Icon customizations
- `tailwind.config.js` - Tailwind configuration (references `theme/colors.js`)

When making theme changes, update the color definitions in `theme/colors.js` and ensure Tailwind config is regenerated.

## Technology Stack

- **Backend**: Ruby 3.x, Rails 7.x, PostgreSQL, Redis
- **Frontend**: Node 23.x, pnpm 10.x, Vue 3, Vite, TailwindCSS
- **Process Management**: Overmind (dev), Sidekiq (jobs)
- **Testing**: RSpec (Ruby), Vitest (JavaScript)
- **Linting**: RuboCop (Ruby), ESLint (JavaScript/Vue)

## Important Notes

- **Package Manager**: Use `pnpm` (not npm/yarn)
- **Node Version**: 23.x (check `.nvmrc`)
- **Ruby Version**: Check `.ruby-version`
- **Working Directory**: Most work happens in `chatwoot/` subdirectory
- **Git Branching**: git-flow model - base branch is `develop`, use `master` for stable
