# VelvetKit
<img width="1512" height="828" alt="Screenshot 2026-10-26 at 9 15 19 PM" src="https://github.com/user-attachments/assets/ffafd932-34d5-4dfe-b314-ca3692fc54bf" />


Accessible UI components for Rails, built on [ViewComponent](https://viewcomponent.org),
Tailwind CSS 4 and Stimulus. Website: **https://velvetkit.com**

VelvetKit doesn't load a component library at runtime. A generator copies the
components you ask for, plus the ones they depend on, into your app. After
that they're your code, under whatever module name you choose, and you can
change them however you like.

```bash
bin/rails generate velvetkit:add dialog
#  create  app/components/ui/base.rb
#  create  app/components/ui/icon.rb
#  create  app/components/ui/spinner.rb
#  create  app/components/ui/button.rb
#  create  app/components/ui/dialog.rb …
#  create  app/javascript/controllers/ui/dialog_controller.ts
```

## Requirements

- Rails 7.1+, Ruby 3.2+
- Tailwind CSS 4
- A JavaScript bundler that compiles TypeScript (Bun or esbuild through
  `jsbundling-rails`). The Stimulus controllers are `.ts` files.

## Install

```ruby
# Gemfile
gem "velvetkit", group: :development
```

```bash
bundle install
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

## Add components

```bash
bin/rails generate velvetkit:add                  # list what's available
bin/rails generate velvetkit:add date_picker menu # add these and what they use
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

## AI agents

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

## Namespacing

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

## Theming

Components style themselves from the CSS variables in `velvetkit.css`
(`--primary`, `--radius`, `--sidebar`, …), with a `.dark` set alongside. To
retheme, change those values. Don't change the components.

For dark mode without a flash on load, add `theme_toggle` and render its
partial in your layout's `<head>`:

```erb
<%= render "layouts/theme_script" %>
```

## Developing VelvetKit

```bash
bundle install
bundle exec rake test:gem         # namespace rewriting, registry, generators
bundle exec rake test:components  # every component, from the registry, as UI::
bundle exec rake test:namespaced  # every component copied out as Kit::, then tested
```

`registry/` holds the components, laid out like a Rails app.
`registry/components.yml` holds only what the files can't say themselves
(descriptions, package and gem versions). Dependencies, Stimulus controllers
and npm imports are read from the source, so they can't drift.

## The docs site (velvetkit.com)

`site/` is a Rails app that serves https://velvetkit.com. It installs the kit
from `registry/` the way any app would, with `bin/sync-kit` (it runs
`velvetkit:install` and `velvetkit:add --all`). The copied files are
gitignored, so the registry is the only source.

The pages build themselves from the registry:

- each component page renders that component's Lookbook preview templates
  live, next to their source
- the "Comes with" list comes from the same dependency scan `add` uses
- the arguments and slots are read from the component's Ruby

To document a component, write or improve its preview. The site picks it up.

```bash
cd site
bun install && bundle install
bin/dev            # sync the kit, then run Rails, JS and CSS watchers
bin/rails test     # every page renders, every live example, SEO and AI endpoints
bin/ux-check       # real clicks, keys and clipboard in headless Chrome (site on :3000)
```

### Deploying

The image is built from the `Dockerfile` at the repository root. It needs
the gem and the registry as well as `site/`.

**Dokploy:** create an Application from this repository with build type
**Dockerfile**. The defaults fit: Dockerfile path `Dockerfile`, context `.`.
Then:

- Environment:
  - `SECRET_KEY_BASE`, required: generate one with `openssl rand -hex 64`.
  - `SITE_URL`, if the site isn't served at https://velvetkit.com.
- Domains: `velvetkit.com` on container port **80**, with HTTPS on. Traefik
  terminates TLS and the app trusts it (`assume_ssl`).
- Health check: the image declares one against `GET /up`.

**Kamal:** fill in the TODOs in `site/config/deploy.yml`, then run
`bin/kamal deploy` from `site/`. It uses the same Dockerfile.

**Anywhere else:**

```bash
docker build -t velvetkit-site .
docker run -p 8080:80 -e SECRET_KEY_BASE=$(openssl rand -hex 64) -e FORCE_SSL=false velvetkit-site
```

### SEO and AI

Every page has its own title, description, canonical URL and Open Graph
and Twitter cards, using `public/og.png`. The home page carries JSON-LD for
`SoftwareApplication` and `WebSite`; docs pages carry `TechArticle` and
`BreadcrumbList`. `/sitemap.xml` and `/robots.txt` are built from the
routes, and robots explicitly welcomes AI crawlers and points them at
`/llms.txt`. Component pages link their Markdown version with
`rel="alternate"`.

## License

MIT
