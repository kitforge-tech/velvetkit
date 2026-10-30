# frozen_string_literal: true

# UI::Toast::Viewport — stacks UI::Toast instances in a corner of the screen.
#
# Render exactly one, anywhere in the layout (it's fixed-positioned, so
# placement in the DOM doesn't matter). It also carries one hidden template
# per variant, which the toast-viewport controller clones to build a toast
# triggered from client-side JS, so a toast looks the same whether it arrived
# via ERB, a Turbo Stream, or `toast()`.
class UI::Toast::Viewport < UI::Base
  ID = "ui-toast-viewport"
  VARIANTS = %i[default success destructive warning info].freeze

  variants(
    base: "fixed z-50 flex flex-col w-full max-w-sm gap-2 p-4 pointer-events-none",
    variants: {
      position: {
        bottom_right:  "bottom-0 right-0 items-end",
        bottom_left:   "bottom-0 left-0 items-start",
        bottom_center: "bottom-0 left-1/2 -translate-x-1/2 items-center",
        top_right:     "top-0 right-0 items-end flex-col-reverse",
        top_left:      "top-0 left-0 items-start flex-col-reverse",
        top_center:    "top-0 left-1/2 -translate-x-1/2 items-center flex-col-reverse"
      }
    },
    defaults: { position: :bottom_right }
  )

  def initialize(position: :bottom_right, id: ID, class: nil, **html_attrs)
    @position   = position
    @id         = id
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :id

  def classes
    cn(variant_classes(position: @position), @user_class)
  end
end
