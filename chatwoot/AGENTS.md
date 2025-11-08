# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
  - Starts 3 processes: Rails server (port 3000), Sidekiq worker, and Vite dev server
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Build Assets**: `bin/vite build` (main app) or `BUILD_MODE=library bin/vite build` (SDK only)
- **Database**: PostgreSQL required; configure via `config/database.yml` or env vars

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

## Styling

- **Tailwind Only**:  
  - Do not write custom CSS  
  - Do not use scoped CSS  
  - Do not use inline styles  
  - Always use Tailwind utility classes  
- **Colors**: Refer to `tailwind.config.js` for color definitions

## General Guidelines

- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- Remove dead/unreachable/unused code
- Don’t write multiple versions or backups for the same logic — pick the best approach and implement it
- Don't reference Claude in commit messages

## Project-Specific

- **Translations**:
  - Only update `en.yml` and `en.json`
  - Other languages are handled by the community
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Architecture Overview

### Backend (Rails)
- **MVC Pattern**: Controllers in `app/controllers/`, Models in `app/models/`, Views (ERB) in `app/views/`
- **API Structure**: RESTful API under `api/v1/` namespace, returns JSON by default
- **Services**: Business logic in `app/services/` (organized by domain: accounts, conversations, contacts, etc.)
- **Jobs**: Background jobs in `app/jobs/` processed by Sidekiq
- **Listeners**: Event-driven architecture using listeners in `app/listeners/`
- **Builders**: Object construction patterns in `app/builders/`
- **Policies**: Authorization logic using policies in `app/policies/`
- **Feature Flags**: Using FlagShihTzu for single-column multi-flag features
- **Storage**: PostgreSQL with JSONB columns for flexible attributes (e.g., `custom_attributes`, `settings`)

### Frontend (Vue 3)
- **Multi-App Structure**:
  - `dashboard/` - Main agent dashboard (Vue 3 + Composition API)
  - `v3/` - New authentication/login pages
  - `widget/` - Customer-facing chat widget
  - `portal/` - Help center portal
  - `survey/` - CSAT survey interface
  - `superadmin_pages/` - Super admin console
- **Build Tool**: Vite with vite-plugin-ruby for asset compilation
- **State Management**: Vuex for shared state
- **Routing**: Vue Router for SPA navigation
- **Components**: Moving to `components-next/` for new design system components
- **Real-time**: ActionCable for WebSocket connections

### Key Integrations
- **Sidekiq**: Background job processing (conversations, emails, notifications)
- **ActionCable**: Real-time updates via WebSockets
- **Active Storage**: File uploads and attachments
- **Devise**: Authentication with token-based auth via devise_token_auth
- **Multiple Channels**: Email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS

### Directory Structure
- `app/actions/` - Command pattern implementations
- `app/dispatchers/` - Event dispatching logic
- `app/drops/` - Liquid template drops for email templates
- `app/finders/` - Query objects for complex data retrieval
- `app/presenters/` - View presentation logic
- `lib/` - Shared libraries and utilities
- `lib/custom_exceptions/` - Custom exception classes
- `enterprise/` - Enterprise edition code overlay

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
