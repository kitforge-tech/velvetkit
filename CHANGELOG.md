# Changelog

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
