# frozen_string_literal: true

# UI::Sheet::Content — the native <dialog> element with a fixed-position panel
# anchored to a viewport edge. Inline block helpers for title, description, and
# footer (no nested ViewComponent sub-classes).
class UI::Sheet::Content < UI::Base
  PANEL_BASE =
    "fixed z-50 flex flex-col overflow-hidden border bg-background p-6 shadow-lg " \
    "data-[state=open]:animate-in data-[state=closed]:animate-out"

  variants(
    base: PANEL_BASE,
    variants: {
      side: {
        right:  "inset-y-0 right-0 h-full w-full border-l sm:max-w-md data-[state=open]:slide-in-from-right data-[state=closed]:slide-out-to-right",
        left:   "inset-y-0 left-0 h-full w-full border-r sm:max-w-md data-[state=open]:slide-in-from-left data-[state=closed]:slide-out-to-left",
        top:    "inset-x-0 top-0 max-h-[80vh] w-full border-b data-[state=open]:slide-in-from-top data-[state=closed]:slide-out-to-top",
        bottom: "inset-x-0 bottom-0 max-h-[80vh] w-full border-t data-[state=open]:slide-in-from-bottom data-[state=closed]:slide-out-to-bottom"
      }
    },
    defaults: { side: :right }
  )

  def initialize(side: :right, show_close: true, class: nil, **html_attrs)
    @side       = side
    @show_close = show_close
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_sheet_context(sheet)
    @sheet = sheet
  end

  # ── Inline slot helpers ───────────────────────────────────────────────────

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

  # ── Class strings ─────────────────────────────────────────────────────────

  def panel_classes
    cn(variant_classes(side: @side), @user_class)
  end

  def dialog_classes
    "fixed inset-0 m-0 p-0 max-w-none max-h-none w-full h-full " \
    "bg-transparent border-0 overflow-visible " \
    "open:flex open:items-center open:justify-center " \
    "backdrop:bg-black/60 backdrop:backdrop-blur-[1px]"
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id]    = @sheet.id
    opts[:class] = dialog_classes
    opts[:"aria-labelledby"]  = @sheet.title_id       if title?
    opts[:"aria-describedby"] = @sheet.description_id if description?
    opts[:"data-ui--dialog-target"] = "content"
    opts[:"data-state"] = "closed"
    opts
  end

  def title_id;       @sheet.title_id;       end
  def description_id; @sheet.description_id; end
end
