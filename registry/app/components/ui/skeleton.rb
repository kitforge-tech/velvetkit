# frozen_string_literal: true

# UI::Skeleton — a pulsing placeholder shown in a piece of content's shape
# while it loads. Purely visual: aria-hidden, since there's nothing here for
# a screen reader to announce. Pair it with a surrounding region that does
# the announcing (role="status", like UI::Spinner already sets up) if the
# loading state itself needs to be heard.
class UI::Skeleton < UI::Base
  variants(
    base: "animate-pulse rounded-md bg-muted",
    variants: {
      shape: {
        text:      "h-4 w-full rounded-sm",
        circle:    "size-10 rounded-full",
        rectangle: "h-24 w-full"
      }
    },
    defaults: { shape: :text }
  )

  def initialize(shape: :text, class: nil, **html_attrs)
    @shape      = shape
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(variant_classes(shape: @shape), @user_class)
  end
end
