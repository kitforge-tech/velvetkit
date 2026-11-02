# VelvetKit

> Accessible ViewComponent UI components for Rails, styled with Tailwind CSS 4
> and wired up with Stimulus. A generator copies the components an app asks
> for, and the ones they depend on, into the app under a namespace it
> chooses. After that they are the app's own code.

## Setting up an app

Requirements: Rails 7.1+, Ruby 3.2+, Tailwind CSS 4, and a JavaScript bundler
that compiles TypeScript (Bun or esbuild through jsbundling-rails). The
Stimulus controllers are `.ts` files, so importmap alone won't do.

```ruby
# Gemfile
gem "velvetkit", group: :development
```

```bash
bundle install
bin/rails generate velvetkit:install --namespace=UI   # or any module name: Kit, Admin…
bin/rails generate velvetkit:add dialog date_picker   # these, plus what they use
bin/rails generate velvetkit:add                      # list every component
```

`install` writes `config/velvetkit.yml` (the namespace and icon library),
adds `view_component` and `tailwind_merge` to the Gemfile, copies the design
tokens (`app/assets/tailwind/velvetkit.css`), translations and the base
component, and writes `docs/velvetkit.md`: a reference for AI agents
covering the components installed in that app, in its namespace. A Claude
Code skill and an AGENTS.md section point agents at it, and `add` keeps it
current.

Generator options: `--namespace=Kit`, `--icons=tabler`, `--all`, `--skip-tests`,
`--skip-previews`, `--skip-packages`, `--skip-ai`, `--force`, `--skip`.

## Icons

Components draw icons from one library: `lucide` (default), `tabler` or
`phosphor`, chosen with `install --icons=phosphor` and kept in
`config/velvetkit.yml`. `add` renames each icon for that library as it copies
a component and copies its SVG to `app/assets/icons`. `UI::Icon.new(name:
"rocket")` draws `app/assets/icons/rocket.svg` inline, on the server. Add
icons with `bin/rails generate velvetkit:icons rocket user`, or with no names
to add every icon the app's views draw that has no SVG yet.

## Namespacing

Components are written against `UI` and rewritten as they are copied. With
`--namespace=Kit`: `UI::Button` becomes `Kit::Button`, `app/components/ui/`
becomes `app/components/kit/`, Stimulus `ui--menu` becomes `kit--menu`, and
I18n `ui.dialog.close_label` becomes `kit.dialog.close_label`. All-capital
names such as `UI` need `inflect.acronym "UI"`, which `install` adds.

## Theming

Components use colour tokens (`bg-primary`, `text-muted-foreground`,
`border-input`), defined in `app/assets/tailwind/velvetkit.css` once for light
and once under `.dark`. Retheme by changing the token values, never the
components. Dark mode is the `dark` class on `<html>`; the `theme_toggle`
component switches it, and its `layouts/theme_script` partial, rendered in
`<head>`, prevents a flash of the light theme.

## Lookbook

Every component comes with Lookbook previews in
`test/components/previews/<namespace>/`. Add `gem "lookbook"` to the
development group and `mount Lookbook::Engine, at: "/lookbook"` in
`config/routes.rb` to browse them.
