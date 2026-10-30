# Agent notes

Conventions for working in this repo (the VelvetKit gem itself — for building
UI *with* an installed VelvetKit, see the app's own `docs/velvetkit.md`,
written by `velvetkit:ai`).

## Where things live

- `registry/` is the only source of truth: every component, its Stimulus
  controller, its locale strings, its test and its Lookbook preview.
- `site/` is the docs app at velvetkit.com. Everything under
  `site/app/components/ui/` and `site/app/javascript/controllers/ui/` is
  **generated, gitignored, and not the thing to edit** — it's a plain copy
  made by `bin/rails generate velvetkit:add <name>` (or `site/bin/sync-kit`
  for everything at once), and it goes stale the moment `registry/` changes
  underneath it. After editing a component, re-run the generator from
  `site/` before expecting the docs site to reflect it:

  ```
  cd site && bin/rails generate velvetkit:add <name> --force --skip-tests --skip-previews --skip-packages --quiet
  ```

  (`--skip-previews`: Lookbook reads previews straight from
  `registry/test/components/previews` — see `config/application.rb` in
  `site/` — so a copy under `site/test/` is always dead weight.)
- `lib/velvetkit/registry.rb` is what actually resolves a component's files,
  dependencies, controllers and npm packages. Read it before assuming
  something needs to be declared by hand.

## Adding or changing a component

`registry/components.yml` needs only a `description:` for a new component.
Everything else — which other components it renders, which Stimulus
controller and npm packages it needs — is discovered by scanning the
component's own source for two patterns, so **don't hand-list what's already
inferable, and don't break the patterns the scanner depends on**:

- `UI::ClassName` anywhere in the `.rb`/`.html.erb` (outside a comment) marks
  a dependency on that component.
- `data-controller: "ui--some-name"` (or any `ui--xxx` string) maps to
  `app/javascript/controllers/ui/some_name_controller.ts`; an `import …
  from './_internal/x.js'` inside that controller pulls in the shared helper
  at `app/javascript/controllers/ui/_internal/x.ts`.

Files for a component named `thing`:

- `registry/app/components/ui/thing.rb` + `thing.html.erb` — or a `thing/`
  subdirectory (`thing/sub_part.rb` → `UI::Thing::SubPart`) for a compound
  component with more than one piece, the way `dialog/`, `sheet/`, `tabs/`
  and `toast/` do.
- Styling via `UI::Base.variants(base:, variants:, defaults:)` and `cn()`
  (tailwind-merge) — look at a sibling component close to what you're
  building (`alert.rb`/`banner.rb` for a simple one, `sheet/content.rb` for a
  side-variant one) rather than inventing a new shape.
- Any rendered string goes in `registry/config/locales/velvetkit.en.yml`
  under `ui.thing.*`, read with `t("ui.thing.the_key", default: "…")` —
  never hardcoded, so a consumer app can translate it.
- Tests at `registry/test/components/ui/thing_test.rb`
  (`ViewComponent::TestCase` + Capybara; every test file starts with the
  `def setup_fixtures(*); end` / `def teardown_fixtures(*); end` boilerplate
  the others have).
- A Lookbook preview at
  `registry/test/components/previews/ui/thing_preview.rb` — this **is** the
  component's documentation; there's no separate hand-written guide page for
  an individual component (the few pages under `site/app/views/docs/` are
  broader topic guides, not per-component docs).

## Before opening a PR

```
bundle exec rubocop
bundle exec rake test     # gem + component tests + a namespaced-rewrite run
```

`rake test` also regenerates every component under a different namespace
(`Kit::` instead of `UI::`) into `tmp/namespaced` and runs its tests there —
this is what proves the namespace rewrite (`Velvetkit::Namespace`) leaves
nothing pointing at the canonical `UI::`. If you add a component that
references another by its literal `UI::` name outside of normal rendering,
this is the run that catches it.

CI (`.github/workflows/ci.yml`) runs rubocop, `bundle-audit` (on both the gem
and `site/`), Brakeman (`site/` only — the gem itself has no controllers or
views), and the test matrix above on Ruby 3.3, 3.4 and 4.0.
