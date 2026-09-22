# shellcheck shell=bash
STACK_TIER="B"
STACK_LABEL="Ruby 3.3 / Rails 7"
STACK_REQUIRES="rails"
STACK_DIRS="app/controllers app/models app/services spec/models spec/requests"
CMD_INSTALL="bundle install"
CMD_TEST="bundle exec rspec"
CMD_LINT="bundle exec rubocop"
CMD_TYPECHECK="echo 'no separate type check — add sorbet or rbs if required (B3)'"
CMD_BUILD="bundle exec rails assets:precompile"
CMD_DEV="bundle exec rails server"
CMD_AUDIT="bundle exec bundler-audit check --update || echo 'bundler-audit not installed'"

stack_generate() {
  [[ -f "$DEST/Gemfile" ]] && { skip "Gemfile already present"; return 0; }
  $DRY_RUN && { skip "would run rails new"; return 0; }
  ( cd "$DEST" && rails new . --skip-git --skip-bundle --api >/dev/null 2>&1 ) || return 1
}
