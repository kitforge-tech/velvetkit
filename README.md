<div align="center">
  <!-- The fragments follow GitHub's theme; <picture> would follow the OS. -->
  <a href="https://velvetkit.com"><img alt="VelvetKit" src="site/public/velvetkit/logo-light.svg#gh-light-mode-only" width="280"></a>
  <a href="https://velvetkit.com"><img alt="VelvetKit" src="site/public/velvetkit/logo-dark.svg#gh-dark-mode-only" width="280"></a>

  <p><strong>Rails UI components you own.</strong><br>
  Accessible ViewComponents styled with Tailwind CSS 4 and wired up with Stimulus,<br>
  copied into your app one at a time, under your namespace.</p>

  <p>
    <a href="https://rubygems.org/gems/velvetkit"><img alt="Gem version" src="https://img.shields.io/gem/v/velvetkit?include_prereleases&color=4D1A7F"></a>
    <a href="https://github.com/kitforge-tech/velvetkit/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/kitforge-tech/velvetkit/actions/workflows/ci.yml/badge.svg"></a>
    <img alt="Rails 7.1+" src="https://img.shields.io/badge/Rails-7.1%2B-CC0000?logo=rubyonrails&logoColor=white">
    <img alt="Tailwind CSS 4" src="https://img.shields.io/badge/Tailwind_CSS-4-38BDF8?logo=tailwindcss&logoColor=white">
    <a href="LICENSE.txt"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-blue"></a>
  </p>

  <p>
    <a href="https://velvetkit.com"><strong>Website</strong></a> ·
    <a href="https://velvetkit.com/docs">Docs</a> ·
    <a href="https://velvetkit.com/docs/components">Components</a> ·
    <a href="https://velvetkit.com/docs/ai">Build with AI</a> ·
    <a href="CHANGELOG.md">Changelog</a>
  </p>
</div>

<br>

<a href="https://velvetkit.com">
  <img alt="The velvetkit.com home page: a sign-in form, a team list, notification switches and a plan picker, all built from VelvetKit components" src="https://github.com/user-attachments/assets/ffafd932-34d5-4dfe-b314-ca3692fc54bf">
</a>

## Why VelvetKit

VelvetKit doesn't load a component library at runtime. A generator copies the
components you ask for, plus the ones they depend on, into your app. After
that they're your code, and you can change them however you like.

- **Only what you use.** `velvetkit:add dialog` brings Dialog and the Button,
  Icon and Spinner it renders, and nothing else.
- **Your namespace.** Components land under `UI::`, `Kit::` or any module you
  choose, with their Stimulus identifiers, translations and DOM ids renamed to match.
- **Accessible by default.** Keyboard support, focus management and ARIA
  wiring are built in, and every component ships with its Minitest tests.
- **Previews included.** Each component comes with Lookbook previews, copied
  alongside it.
- **Themeable.** Everything styles itself from CSS variables, with dark mode
  and no flash on load.
- **Ready for AI agents.** Your coding agent gets a reference of the
  components you've installed, so it uses them instead of inventing new ones.

## Quick start

```ruby
# Gemfile
gem "velvetkit", group: :development
```

```bash
bundle install
bin/rails generate velvetkit:install     # components under UI::
bin/rails generate velvetkit:add dialog  # Dialog, and what it uses
```

```bash
#  create  app/components/ui/base.rb
#  create  app/components/ui/icon.rb
#  create  app/components/ui/spinner.rb
#  create  app/components/ui/button.rb
#  create  app/components/ui/dialog.rb …
#  create  app/javascript/controllers/ui/dialog_controller.ts
```

```erb
<%= render(UI::Button.new(variant: :outline)) { "Save draft" } %>
```

### Requirements

- Rails 7.1+, Ruby 3.2+
- Tailwind CSS 4
- A JavaScript bundler that compiles TypeScript (Bun or esbuild through
  `jsbundling-rails`). The Stimulus controllers are `.ts` files.

## Components

38 components, each with live examples on [velvetkit.com](https://velvetkit.com/docs/components):

[Accordion](https://velvetkit.com/docs/components/accordion) ·
[Alert](https://velvetkit.com/docs/components/alert) ·
[Avatar](https://velvetkit.com/docs/components/avatar) ·
[AvatarGroup](https://velvetkit.com/docs/components/avatar_group) ·
[Badge](https://velvetkit.com/docs/components/badge) ·
[Banner](https://velvetkit.com/docs/components/banner) ·
[Breadcrumb](https://velvetkit.com/docs/components/breadcrumb) ·
[Button](https://velvetkit.com/docs/components/button) ·
[ButtonTo](https://velvetkit.com/docs/components/button_to) ·
[Card](https://velvetkit.com/docs/components/card) ·
[Checkbox](https://velvetkit.com/docs/components/checkbox) ·
[DataGrid](https://velvetkit.com/docs/components/data_grid) ·
[DatePicker](https://velvetkit.com/docs/components/date_picker) ·
[Dialog](https://velvetkit.com/docs/components/dialog) ·
[Divider](https://velvetkit.com/docs/components/divider) ·
[Icon](https://velvetkit.com/docs/components/icon) ·
[Image](https://velvetkit.com/docs/components/image) ·
[Input](https://velvetkit.com/docs/components/input) ·
[InputGroup](https://velvetkit.com/docs/components/input_group) ·
[Label](https://velvetkit.com/docs/components/label) ·
[Link](https://velvetkit.com/docs/components/link) ·
[Menu](https://velvetkit.com/docs/components/menu) ·
[NativeSelect](https://velvetkit.com/docs/components/native_select) ·
[Pagination](https://velvetkit.com/docs/components/pagination) ·
[PasswordInput](https://velvetkit.com/docs/components/password_input) ·
[Popover](https://velvetkit.com/docs/components/popover) ·
[RadioGroup](https://velvetkit.com/docs/components/radio_group) ·
[Select](https://velvetkit.com/docs/components/select) ·
[Sheet](https://velvetkit.com/docs/components/sheet) ·
[Sidebar](https://velvetkit.com/docs/components/sidebar) ·
[Spinner](https://velvetkit.com/docs/components/spinner) ·
[Switch](https://velvetkit.com/docs/components/switch) ·
[Table](https://velvetkit.com/docs/components/table) ·
[Tabs](https://velvetkit.com/docs/components/tabs) ·
[Text](https://velvetkit.com/docs/components/text) ·
[ThemeToggle](https://velvetkit.com/docs/components/theme_toggle) ·
[Tooltip](https://velvetkit.com/docs/components/tooltip) ·
[Typography](https://velvetkit.com/docs/components/typography)

## Usage

### Install

```bash
bin/rails generate velvetkit:install                 # components under UI::
bin/rails generate velvetkit:install --namespace=Kit # or under Kit::
```

`install` does the following:

- writes `config/velvetkit.yml` with the namespace
- adds `view_component` and `tailwind_merge` to the Gemfile
- adds an acronym inflection when the namespace needs one (`UI`, not `Kit`)
- copies the base component, design tokens (`app/assets/tailwind/velvetkit.css`),
  translations (`config/locales/velvetkit.en.yml`) and Lucide icon setup
  (`app/javascript/velvetkit_icons.ts`), and imports the CSS and icons from
  your entry points
- installs `@hotwired/stimulus`, `lucide` and `tw-animate-css` with your
  package manager, which it picks from your lockfile

### Add components

```bash
bin/rails generate velvetkit:add                  # list what's available
bin/rails generate velvetkit:add date_picker menu # add these and what they use
bin/rails generate velvetkit:add --all            # everything
```

`add` does the following for each component:

- copies the component, its templates and sub-components
- copies its Stimulus controllers and any lazily-loaded entry points (AG Grid
  for `data_grid`, Cally for `date_picker`)
- copies its Minitest tests and Lookbook previews. A preview that shows
  components you haven't added is skipped, and `add` tells you which.
- registers its controllers in `app/javascript/controllers/index.js` when
  that file lists controllers one by one
- installs any npm packages it needs, and adds any gems it needs (`pagy` for
  `pagination`) to the Gemfile

Options: `--namespace=Kit`, `--skip-tests`, `--skip-previews`,
`--skip-packages` (list the packages instead of installing them), and the usual
`--force`/`--skip` for files that already exist.

### AI agents

`install` also writes three files so coding agents use your components
instead of inventing new ones:

- `docs/velvetkit.md`: the rules for building UI with the kit, then every
  installed component's arguments, slots, notes and working examples, all in
  your namespace. `add` rewrites it whenever you add components.
- `.claude/skills/velvetkit/SKILL.md`: a Claude Code skill pointing at it.
- A short section in `AGENTS.md` pointing at it, for Codex, Cursor and others.
  Your own notes in that file are kept.

Run `bin/rails generate velvetkit:ai` to regenerate them, or install with
`--skip-ai` to leave them out. velvetkit.com also serves
[llms.txt](https://velvetkit.com/llms.txt), and every component page has a
Markdown version.

### Namespacing

Every component is written once, against `UI`. The generators rewrite each file
as they copy it, so with `--namespace=Kit`:

| In the registry              | In your app                   |
| ---------------------------- | ----------------------------- |
| `UI::Button`                 | `Kit::Button`                 |
| `app/components/ui/`         | `app/components/kit/`         |
| `data-controller="ui--menu"` | `data-controller="kit--menu"` |
| `t("ui.dialog.close_label")` | `t("kit.dialog.close_label")` |
| `"ui-dialog-#{id}"`          | `"kit-dialog-#{id}"`          |

The namespace must be a single constant name, like `UI`, `Kit` or `VelvetKit`.

### Theming

Components style themselves from the CSS variables in `velvetkit.css`
(`--primary`, `--radius`, `--sidebar`, …), with a `.dark` set alongside. To
retheme, change those values. Don't change the components.

For dark mode without a flash on load, add `theme_toggle` and render its
partial in your layout's `<head>`:

```erb
<%= render "layouts/theme_script" %>
```

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/kitforge-tech/velvetkit/issues).

```bash
bundle install
bundle exec rake test             # all three suites below
bundle exec rake test:gem         # namespace rewriting, registry, generators
bundle exec rake test:components  # every component, from the registry, as UI::
bundle exec rake test:namespaced  # every component copied out as Kit::, then tested
bundle exec rubocop
```

`registry/` holds the components, laid out like a Rails app.
`registry/components.yml` holds only what the files can't say themselves
(descriptions, package and gem versions). Dependencies, Stimulus controllers
and npm imports are read from the source, so they can't drift.

To document a component, write or improve its Lookbook preview: the docs
site renders previews live. `site/` is the Rails app behind velvetkit.com;
see [site/README.md](site/README.md) to run and deploy it.

### Releasing

1. Bump `VERSION` in `lib/velvetkit/version.rb` and add a `CHANGELOG.md`
   entry, in a pull request.
2. Once it's merged, tag the merge commit and push the tag:

   ```bash
   git tag v0.1.1.beta && git push origin v0.1.1.beta
   ```

The [release workflow](.github/workflows/release.yml) checks the tag matches
the version, runs the tests and publishes the gem to RubyGems.

## Licence

VelvetKit is released under the [MIT licence](LICENSE.txt).

<br>

<div align="center">
  <sub>Built by <a href="https://kitforge.tech">KitForge</a></sub>
</div>
