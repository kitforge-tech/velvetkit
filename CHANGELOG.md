# Changelog

## Unreleased

New components:

- `Timeline`: dated entries down the page (order status, stock history, an
  activity log), drawn as circles, dots or circles in a colour each.
- `NumberInput`: a number field with - and + buttons that keep counting while
  held; `change` fires once on release, so a cart row submits once.
- `Gallery`: product photos with thumbnails and swiping, opening over the
  page to zoom and pan, or `zoom: :hover` for a lens and a magnified pane.
- `Chart`: line, bar, stacked bar, pie and donut charts on Chart.js, with a
  legend, tooltips, keyboard reading, a table of the numbers, and animation.
  The docs site has a Charts section with a page for each.
- `Progress`: a bar for an upload, an import or storage used, with a value or
  sliding while there's none yet, in tones, and split into coloured segments
  with a legend. Setting its value attribute from JavaScript moves it live.
- `Kbd`: a key or shortcut, shown as each reader's computer labels it (⌘ on a
  Mac, Ctrl on Windows, Super on Linux), with `bind:` to press a button or
  focus a field when the shortcut is pressed.
- `Command`: a search box over pages, actions and records, inline or opened
  with ⌘K, ranking by best match, with groups, shortcuts, and server search
  with `url:`.
- `Slider`: a handle to drag for a value, or two for a range such as a price
  band, with value text, labelled marks and form binding. The knob follows
  the pointer freely and the value keeps to the step.
- `MoneyInput`: an amount of money, grouped as it's typed (1,23,456.78 for
  rupees, 123,456.78 otherwise) with its currency sign, decimals filled in
  when the field is left, and the plain number (123456.78) posted in a
  hidden field. The sign, separators and decimals follow the app's locale.
  ↑ and ↓ step by one unit, or `step:`, and Shift by ten.

Changes:

- `Select` searches the server as you type with `url:` (JSON back), with a
  spinner when it's slow, results remembered for a minute, and choices kept
  when later searches no longer list them.
- `DatePicker` moves from Cally to Vanilla Calendar Pro and takes
  `range: true` for From and To, with presets such as Last 7 days, two months
  side by side, and a hover preview. Typed dates take digits only, the
  separators go in as you type, and the calendar opens on click or focus.
- `FileField` shows a tile for each chosen file, checks `accept:` and
  `max_size:`, and with `direct_upload: true` sends each file to storage
  through Active Storage as it's chosen, with a progress bar. Bound to a
  form, it shows the record's attachments.
- The chart colours, `--chart-1` to `--chart-5`, are now velvet, orange,
  aqua, blue and magenta, checked for colour-blind readers in both themes.
- `velvetkit:add` puts the bundles Chart, Date Picker and Data Grid load on
  demand (`chart_js.ts`, `vanilla_calendar.ts`, `ag_grid.ts`) into the app's
  JavaScript build: `bun.config.js`, `webpack.config.js`, or a build script
  that lists `application.js`. Before, they were copied but never built, so
  those components failed to load their library.

Upgrading an app: re-run `velvetkit:add` for `date_picker`, `select` and
`file_field`, and copy the new `--chart-*` values into your `velvetkit.css`.
`date_picker` now needs `vanilla-calendar-pro` instead of `cally`, and loads
`app/javascript/vanilla_calendar.ts` as its own entry point; `file_field`
needs `@rails/activestorage`. If you added `chart_js.ts`,
`vanilla_calendar.ts` or `ag_grid.ts` to your build by hand, `add` leaves
it as it is. `progress` needs the `velvetkit-progress` keyframes from the new
`velvetkit.css`; without them a bar with no value doesn't move.

- The docs site's search is the kit's own `Command`.
- Fix: Rails 8.1.4.1, for security advisories in Active Storage and Action Pack.
- Fix: the docs site shows a component added to the catalog without a server
  restart.

## 0.3.0 — 2026-11-03

- `Stepper`: the steps of a multi-step form, done, current or to come, with
  dots, centred labels, panels moved between in the browser, and links back
  to done steps.
- `ConfirmDialog`: a styled dialog that answers `data-turbo-confirm`, so every
  existing confirm uses it.
- `ToggleGroup`: a row of buttons choosing one or several, posting like
  radios or checkboxes.
- `EmptyState`: an icon, title, text and actions for a page with nothing to
  list.
- Icons come from Lucide, Tabler or Phosphor, chosen with
  `velvetkit:install --icons=`, and are drawn as inline SVG.

## 0.2.2 — 2026-11-02

- Fix: the `plus`, `search`, `ellipsis-vertical` and `grip-vertical` icons were
  missing from installs.

## 0.2.1 — 2026-11-01

- `NavigationMenu`: site navigation with links and panels of rich links that
  open on hover or click.

## 0.2.0 — 2026-11-01

- `Toast`: stacked messages that dismiss themselves.
- `SessionTabs`: tabs for open sessions, with a button to add one.
- `Skeleton` and `FileField`.
- Fix: `Menu` content positions itself with the fixed strategy, so it isn't
  clipped by a scrolling container.
- Fix: dependencies updated for security advisories in `addressable` and `rack`.

## 0.1.0.beta — 2026-10-26

- First release of the component library.
- `velvetkit:install` and `velvetkit:add` generators, with a configurable namespace.
- 39 components, their Stimulus controllers, tests and Lookbook previews.
- `Select` is a styled dropdown (listbox, keyboard, type-ahead), with
  `searchable:` and `multiple:`; it posts through a hidden native select, so
  forms work unchanged. The browser's own control is now `NativeSelect`.
- `velvetkit:add --all`, and support for cssbundling-rails Tailwind entry points.
- Docs site for velvetkit.com in `site/`, built from the registry.
- `velvetkit:ai`, run by `install` and kept current by `add`: `docs/velvetkit.md`,
  a Claude Code skill and an AGENTS.md section, so agents use the kit.
- Primary colour is velvet, `#4D1A7F`, lifted in dark mode to stay readable.
- Fix: `Icon` dropped its icon name when given `data:` attributes.
