# frozen_string_literal: true

# UI::Dialog::Content — the native <dialog> element. Exposes block helpers for
# the optional title, description, and footer regions instead of nested
# ViewComponent sub-classes (one file, fewer indirections).
class UI::Dialog::Content < UI::Base
  PANEL_BASE =
    "relative flex flex-col w-full max-h-[calc(100vh-2rem)] overflow-hidden " \
    "rounded-lg border bg-background p-6 shadow-lg " \
    "data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95 " \
    "data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95"

  variants(
    base: PANEL_BASE,
    variants: {
      size: {
        sm:      "max-w-md",
        default: "max-w-lg",
        lg:      "max-w-2xl",
        xl:      "max-w-4xl"
      }
    },
    defaults: { size: :default }
  )

  def initialize(size: :default, show_close: true, class: nil, **html_attrs)
    @size       = size
    @show_close = show_close
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_dialog_context(dialog)
    @dialog = dialog
  end

  # ── Inline slot helpers (block ↔ text) ────────────────────────────────────

  def with_title(text = nil, &block)
    @title_text  = text
    @title_block = block
    self
  end

  def with_description(text = nil, &block)
    @description_text  = text
    @description_block = block
    self
  end

  def with_footer(&block)
    @footer_block = block
    self
  end

  def title?;       @title_text.present? || @title_block.present?;             end
  def description?; @description_text.present? || @description_block.present?; end
  def footer?;      @footer_block.present?;                                    end
  def show_close?;  @show_close;                                               end

  def title_html
    @title_block ? view_context.capture(&@title_block) : @title_text
  end

  def description_html
    @description_block ? view_context.capture(&@description_block) : @description_text
  end

  def footer_html
    view_context.capture(&@footer_block) if @footer_block
  end

  # ── Class strings ────────────────────────────────────────────────────────

  def panel_classes
    cn(variant_classes(size: @size), @user_class)
  end

  # The native <dialog> takes the full viewport and centers the panel inside.
  # Backdrop styling is owned by the ::backdrop pseudo-element so we don't
  # need a separate overlay div.
  def dialog_classes
    "fixed inset-0 m-0 p-0 max-w-none max-h-none w-full h-full " \
    "bg-transparent border-0 overflow-visible " \
    "open:flex open:items-center open:justify-center " \
    "backdrop:bg-black/60 backdrop:backdrop-blur-[1px]"
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id]    = @dialog.id
    opts[:class] = dialog_classes
    opts[:"aria-labelledby"]  = @dialog.title_id       if title?
    opts[:"aria-describedby"] = @dialog.description_id if description?
    opts[:"data-ui--dialog-target"] = "content"
    opts[:"data-state"] = "closed"
    opts
  end

  def title_id;       @dialog.title_id;       end
  def description_id; @dialog.description_id; end
end
