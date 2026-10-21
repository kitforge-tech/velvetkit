# VelvetKit components in this app

This app builds its UI from VelvetKit components: ViewComponents styled with
Tailwind CSS 4 and wired up with Stimulus. They were copied into the app by
the `velvetkit` gem and are now the app's own code, under `UI::`.

Use them for every new screen. Reach for raw HTML and Tailwind only when no
component fits, and never build a second version of a component that exists.

## Where things are

- Components: `app/components/ui/` (`UI::Button` is `app/components/ui/button.rb`)
- Their Stimulus controllers: `app/javascript/controllers/ui/`, registered as `ui--<name>`
- Tests: `test/components/ui/` (Minitest, `render_inline`)
- Lookbook previews: `test/components/previews/ui/`
- Design tokens: `app/assets/tailwind/velvetkit.css`
- Strings: `config/locales/velvetkit.en.yml`, under `ui.`
- Icons: `app/javascript/velvetkit_icons.ts`

## Rules

1. **Render, with slots.** Components take keyword arguments and fill their
   parts through `with_*` slots in a block:

   ```erb
   <%= render(UI::Card.new) do |card| %>
     <% card.with_header do |header| %>
       <% header.with_title { "Billing" } %>
     <% end %>
     <% card.with_content { "…" } %>
   <% end %>
   ```

2. **Pass `class:` to adjust, not to restyle.** Your classes are merged with
   the component's by tailwind_merge, and yours win on conflict. For a
   different look, use a `variant:` or `size:` the component already has.

3. **Never hardcode colours.** Use the tokens: `bg-primary`,
   `text-muted-foreground`, `border-input`, `bg-card`, `text-destructive`.
   They switch with dark mode. Hex values and `blue-600` don't.

4. **Need a component the app doesn't have yet?** Add it from the kit rather
   than writing one: `bin/rails generate velvetkit:add <name>`. It copies the
   component with everything it depends on, and refreshes this file.
   Available: {{available}}.

5. **Icons are Lucide names** (`UI::Icon.new(name: "calendar")`). An icon the
   app hasn't used before must be added to `app/javascript/velvetkit_icons.ts`,
   in both the import list and the `icons` object, or it renders empty.

6. **User-facing text goes through I18n**, as the components' own strings do.

7. **Changing a component is fine**, it's app code. Keep its test passing, and
   update its Lookbook preview so the change can be seen.

8. **Links that look like buttons** use `UI::Link.new(href:, variant:, button_variant: true)`.
   Without `button_variant: true` a link is styled as text.

## Components installed here

Each section below lists a component's arguments, slots and working
examples. The examples are the same templates its Lookbook previews render.
