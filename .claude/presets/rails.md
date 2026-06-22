# Preset B3 — Ruby on Rails

> Copy-paste this block into the **B3** section of CLAUDE.md, then adapt.

---

### Code conventions

- Rails convention-over-configuration architecture — don't fight the framework
- Skinny controllers, fat models (business logic in models or service objects)
- Service objects in `app/services/` for complex multi-model logic
- Query objects in `app/queries/` for complex ActiveRecord queries
- No logic in views — helpers and presenters only
- `ActiveRecord` via named associations and scopes — no raw SQL (except documented optimizations)
- `before_*` / `after_*` callbacks limited to simple cases — prefer service objects
- Explicit serializers for JSON responses (jbuilder or ActiveModel::Serializer)
- `strong_parameters` required on all controllers
- Environment variables via `dotenv` in dev, vault / secrets manager in production

### Tests

- Framework: RSpec + FactoryBot + Shoulda Matchers
- Minimum coverage: 80% (SimpleCov)
- `rails_helper` for Rails-loading tests, `spec_helper` for pure tests
- Factories instead of fixtures — `FactoryBot.lint` in CI
- Mocks: typed `instance_double` and `class_double` — never untyped `double`
- Request specs for API endpoints — not controller specs
- Naming pattern: `describe [Subject]` + `context [Scenario]` + `it [Result]`

### Lint & Quality

- `RuboCop` with `rubocop-rails`, `rubocop-rspec`, `rubocop-performance`
- `.rubocop.yml` versioned — zero offenses in CI
- `Brakeman` for static security audit (injection, XSS, mass assignment…)
- `bundler-audit` for CVEs in gems

### Commands (B4)

```bash
# Install
bundle install

# DB
rails db:create db:migrate

# Test
bundle exec rspec --format progress

# Lint
bundle exec rubocop
bundle exec brakeman -q

# Dependency audit
bundle exec bundler-audit check --update

# Run locally
rails server -e development
```

### Typical structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   └── api/
│       └── v1/
│           └── <resource>_controller.rb
├── models/
│   ├── application_record.rb
│   └── <entity>.rb
├── services/
│   └── <domain>/
│       └── <action>_service.rb       # e.g. users/create_service.rb
├── queries/
│   └── <entity>_query.rb
├── serializers/
│   └── <entity>_serializer.rb
└── policies/                         # Pundit for authorization
    └── <entity>_policy.rb
spec/
├── models/
├── requests/                         # HTTP endpoint tests
├── services/
├── factories/
│   └── <entity>.rb
└── support/
    ├── factory_bot.rb
    └── shoulda_matchers.rb
```

### Recommended Gemfile (API)

```ruby
# Core
gem 'rails', '~> 7.2'
gem 'pg'
gem 'puma'

# Auth
gem 'devise'
gem 'jwt'

# Authorization
gem 'pundit'

# Serialization
gem 'jsonapi-serializer'

# Background jobs
gem 'sidekiq'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
end

group :test do
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end
```
