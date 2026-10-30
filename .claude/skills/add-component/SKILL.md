---
name: add-component
description: Add a new component to the VelvetKit registry, or add a sub-part to an existing one. Use when asked to build, add or scaffold a UI component in this repo (not in an app that has installed VelvetKit — that's a different skill).
---

Read `AGENTS.md` first — it has the registry's auto-discovery rules
(`UI::ClassName` references, `ui--name` controller strings) that this skill's
steps depend on, and the file-layout conventions for compound components.

For a new component named `thing` (swap in the real name throughout):

1. **Catalog entry.** Add to `registry/components.yml`, alphabetically, with
   only a `description:` — one sentence, same voice as its neighbors (read a
   few nearby entries first).

2. **Component files.**
   `registry/app/components/ui/thing.rb` + `thing.html.erb`. Find the
   sibling component closest in shape to what you're building and copy its
   structure — the `variants()` DSL, `cn()` usage, `data:`/`aria:` hash
   style, slot helpers (`renders_one`) — rather than inventing a new shape.
   Good references: `alert.rb` (simple, variants + icon + dismiss),
   `banner.rb` (dismiss button + action slot), `sheet/content.rb` (a `side:`-
   style variant with enter/exit animation), `toast.rb` +
   `toast/viewport.rb` (a component with a client-triggerable JS path).
   A compound component (more than one renderable piece) gets a `thing/`
   subdirectory instead of a flat file — `thing/sub_part.rb` becomes
   `UI::Thing::SubPart`.

3. **Stimulus controller**, only if the component needs JS behavior:
   `registry/app/javascript/controllers/ui/thing_controller.ts`, wired from
   the template with `data: { controller: "ui--thing" }`. Match the style of
   a controller doing something similar — `banner_controller.ts` for a
   one-line dismiss, `tooltip_controller.ts` for timers/cleanup in
   `connect()`/`disconnect()`, `dialog_controller.ts` for native-element
   delegation. Don't reach for a new npm package unless the behavior is
   genuinely hard (positioning math, calendar logic) — most components here
   are plain Stimulus, no dependency.

4. **i18n.** Any string the component renders (button labels, aria-labels,
   placeholders) goes in `registry/config/locales/velvetkit.en.yml` under a
   new `ui.thing:` key, read with
   `t("ui.thing.the_key", default: "The literal default")`.

5. **Test.** `registry/test/components/ui/thing_test.rb`. Copy the
   boilerplate from an existing test file verbatim (`require "test_helper"`,
   `ViewComponent::TestCase`, `def setup_fixtures(*); end` / `def
   teardown_fixtures(*); end`), then write real assertions: container
   renders, each variant's classes, each slot, dismiss/close wiring if any,
   `class:`/html-attribute passthrough. A compound component's sub-part gets
   its own test file at `registry/test/components/ui/thing/sub_part_test.rb`.

6. **Lookbook preview.** `registry/test/components/previews/ui/thing_preview.rb`
   — this is the component's documentation, there's no separate guide page
   to write. A `# @label Playground` method with `@param` annotations for the
   main knobs, plus a few `render_with_template` methods backed by
   `thing_preview/some_demo.html.erb` files for fixed scenarios (all
   variants side by side, a dismissible example, etc.).

7. **Verify.**
   ```
   bundle exec rubocop registry/app/components/ui/thing.rb registry/test/components/ui/thing_test.rb …
   bundle exec rake test
   ```
   Then, if you need to see it rendered: from `site/`, run
   `bin/rails generate velvetkit:add thing --force --skip-tests --skip-previews --skip-packages --quiet`
   to sync the docs app's copy, and check it at `localhost:3000/lookbook` —
   see "Where things live" in `AGENTS.md` for why this sync step is needed
   after every edit, not just the first time.

Don't stop at "it renders" — actually exercise what you built (click the
dismiss button, trigger the auto-dismiss timer, check both light and dark)
before calling it done.
