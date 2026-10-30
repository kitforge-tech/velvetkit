# frozen_string_literal: true

# UI::Toast — a single dismissible, auto-expiring message.
#
# A toast has nowhere to appear on its own: render a UI::Toast::Viewport once
# per page (e.g. in the layout), then push toasts into it either from the
# server, by appending one in a Turbo Stream response —
#
#   turbo_stream.append(UI::Toast::Viewport::ID, render(UI::Toast.new(variant: :success, title: "Saved")))
#
# — or from the client, with the `toast()` helper exported by the
# toast-viewport controller.
class UI::Toast < UI::Base
  DEFAULT_ICONS = {
    default:     "info",
    success:     "circle-check",
    destructive: "circle-alert",
    warning:     "circle-alert",
    info:        "info"
  }.freeze

  # The same motion in reverse for in/out, and explicitly longer than the
  # plugin's 150ms default: fine for an 8px tooltip nudge, too snappy for a
  # whole card to travel, which read as an unsmoothed flicker rather than a
  # dismissal. The ui--toast controller's own EXIT_DURATION constant waits
  # this same 300ms before removing a dismissed toast from the DOM — keep
  # them in sync if this changes.
  #
  # A neutral bg-popover surface, same as Dialog/Sheet/Popover/Menu — the
  # other floating, elevated surfaces in the kit. Variant color is carried by
  # the icon alone, nothing else on the card changes: Alert is the one place
  # that tints its whole surface, because it sits inline in the page rather
  # than floating above it.
  # fill-mode-forwards matters here specifically: tw-animate-css's
  # animate-in/animate-out default to animation-fill-mode: none, so without
  # it the element snaps back to its unanimated state (fully visible, no
  # transform) the instant the exit animation ends — a flicker right before
  # the timeout below removes it. Dialog/Sheet never hit this because they
  # never remove the element after animating; Toast is the first thing here
  # that does.
  variants(
    base: "relative flex w-full items-start gap-3 rounded-lg border bg-popover p-4 " \
          "text-popover-foreground shadow-lg pointer-events-auto duration-300 fill-mode-forwards " \
          "data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:slide-in-from-bottom-2 " \
          "data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:slide-out-to-bottom-2 " \
          "[&>i]:translate-y-0.5 [&>i]:shrink-0",
    variants: {
      variant: {
        default:     "[&>i]:text-muted-foreground",
        success:     "[&>i]:text-emerald-600 dark:[&>i]:text-emerald-400",
        destructive: "[&>i]:text-destructive",
        warning:     "[&>i]:text-amber-600 dark:[&>i]:text-amber-400",
        info:        "[&>i]:text-sky-600 dark:[&>i]:text-sky-400"
      }
    },
    defaults: { variant: :default }
  )

  renders_one :action, ->(**opts, &block) { tag.div(class: "mt-2", **opts, &block) }

  # duration is seconds before the toast dismisses itself; 0 (or nil) leaves
  # it on screen until the visitor dismisses it. Takes a plain number of
  # seconds or an ActiveSupport::Duration (duration: 10.seconds).
  def initialize(variant: :default, title: nil, description: nil, duration: 5,
                 dismissible: true, icon: true, class: nil, **html_attrs)
    @variant     = variant
    @title       = title
    @description = description
    @duration_ms = duration.to_i * 1000
    @dismissible = dismissible
    @icon_name   = icon == true ? DEFAULT_ICONS.fetch(variant, "info") : icon
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  def classes
    cn(variant_classes(variant: @variant), @user_class)
  end

  def title?;       @title.present?;       end
  def description?; @description.present?; end
  def icon?;        @icon_name.present?;   end
  def dismissible?; @dismissible;           end

  # A destructive toast interrupts (assertive); anything else just announces
  # once it's there (polite), same split Alert makes for role/aria-live.
  def role;      @variant == :destructive ? "alert"     : "status"; end
  def live;      @variant == :destructive ? "assertive" : "polite";  end
end
