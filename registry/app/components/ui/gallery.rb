# frozen_string_literal: true

# A product's photos: one large image, thumbnails to pick another, and two ways
# to look closer.
#
#   <%= render(UI::Gallery.new(label: "Photos of the ceramic mug")) do |gallery| %>
#     <% gallery.with_image(src: "mug.jpg", alt: "Mug, front", zoom_src: "mug-2000.jpg", thumbnail_src: "mug-160.jpg") %>
#     <% gallery.with_image(src: "mug-side.jpg", alt: "Mug, from the side") %>
#   <% end %>
#
# The main view is a scroll-snap strip, so it swipes on a touch screen with no
# script involved. Previous and next wrap round, and arrow keys do the same.
# Only the first image loads with the page. `zoom_src:` and `thumbnail_src:` are
# optional, and worth giving: the zoomed image only downloads when someone opens
# it, so it can be much larger than `src:`.
#
# Clicking the image opens it by itself over the dimmed page, with zoom and close
# in the top corners and previous and next at the sides. There, clicking zooms in
# on that spot and clicking again zooms out; so do the buttons, the + and - keys,
# 0 to reset, and pinching a trackpad. A zoomed image pans by dragging or
# scrolling. Clicking outside it or pressing Escape closes it. The image grows
# out of its place on the page and returns there, and all the movement stops for
# anyone whose system asks for reduced motion.
#
# `zoom: :hover` adds what big shops do: moving a mouse over the image shows a
# lens on it and that part magnified beside it, `zoom_scale:` times over (2.5 by
# default). With no room beside it, the magnified part shows over the image. A
# click still opens the overlay, which is also what touch screens and the
# keyboard get, having no mouse to hover with.
#
# `aspect:` is :square, :landscape or :portrait, and `fit:` is :contain (the whole
# photo) or :cover (fills the frame, cropping). A single image gets no thumbnails
# or arrows.
class UI::Gallery < UI::Base
  ASPECTS = { square: "aspect-square", landscape: "aspect-video", portrait: "aspect-[4/5]" }.freeze
  FITS = { contain: "object-contain", cover: "object-cover" }.freeze
  ZOOMS = %i[overlay hover].freeze

  HIDE_SCROLLBAR = "[scrollbar-width:none] [&::-webkit-scrollbar]:hidden"

  # The lens and pane fade in and out, rather than blinking on and off with `hidden`.
  HOVER_REVEAL = "pointer-events-none invisible absolute opacity-0 transition-[opacity,scale,visibility] duration-150 " \
                 "data-[shown]:visible data-[shown]:opacity-100 motion-reduce:transition-none"

  # Always light on the dark backdrop, whatever the page's theme, ring included.
  # The border keeps them in sight on a dark page, where the backdrop is black too.
  OVERLAY_BUTTON = "rounded-full border border-white/25 bg-black/60 text-white hover:bg-black/80 hover:text-white " \
                   "focus:ring-white disabled:bg-black/60! disabled:text-white/50!"

  renders_many :images, UI::Gallery::Image

  def initialize(label: nil, aspect: :square, fit: :contain, zoom: :overlay, zoom_scale: 2.5, class: nil, **html_attrs)
    @label      = label
    @aspect     = ASPECTS.key?(aspect.to_sym) ? aspect.to_sym : :square
    @fit        = FITS.key?(fit.to_sym) ? fit.to_sym : :contain
    @zoom       = ZOOMS.include?(zoom.to_sym) ? zoom.to_sym : :overlay
    @zoom_scale = zoom_scale
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def render? = images.any?
  def multiple? = images.size > 1
  def hover_zoom? = @zoom == :hover

  def root_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:role] = "group"
    attrs[:class] = cn("flex w-full min-w-0 flex-col gap-3", @user_class)
    attrs[:aria] = { label: label, roledescription: t("ui.gallery.roledescription", default: "gallery") }
                   .merge(@html_attrs[:aria] || {})
    attrs[:data] = { slot: "gallery", controller: "ui--gallery", zoom: @zoom,
                     "ui--gallery-zoom-scale-value": @zoom_scale,
                     "ui--gallery-position-value": position_format,
                     action: "keydown@window->ui--gallery#keydown resize@window->ui--gallery#layout" }
                   .merge(@html_attrs[:data] || {})
    attrs
  end

  def track_classes
    cn("flex snap-x snap-mandatory overflow-x-auto rounded-lg bg-muted", HIDE_SCROLLBAR)
  end

  def slide_classes = cn("w-full shrink-0 snap-center", ASPECTS[@aspect])

  def slide_button_attrs(image, index)
    # One tab stop for the strip: the image showing. The rest are out of sight.
    { type: "button", tabindex: index.zero? ? 0 : -1,
      class: cn("group/slide relative block size-full rounded-lg transition-all focus:outline-none",
                "focus:ring-2 focus:ring-inset focus:ring-primary", hover_zoom? ? "cursor-crosshair" : "cursor-zoom-in"),
      aria: { label: phrase(t("ui.gallery.zoom", default: "Zoom image %{current}: %{alt}"), current: index + 1, alt: image.alt),
              haspopup: "dialog" },
      data: { action: slide_action, "ui--gallery-index-param": index } }
  end

  # Covers the window with nothing of its own: only the image and its buttons sit
  # on the backdrop.
  def dialog_classes
    "m-0 size-full max-h-none max-w-none overflow-hidden bg-transparent p-0 outline-none backdrop:bg-black/80"
  end

  def viewport_classes
    cn("group/viewport absolute inset-0 flex overflow-auto overscroll-contain", HIDE_SCROLLBAR)
  end

  def image_classes = cn("size-full", FITS[@fit])

  # Only the first image loads with the page. The rest wait to be scrolled to.
  def image_loading(index) = index.zero? ? :eager : :lazy

  # The padding leaves room for the focus ring, and the margin takes it back, so
  # the first thumbnail lines up with the edge of the image.
  def thumbnail_strip_classes = cn("-mx-1 flex gap-2 overflow-x-auto p-1", HIDE_SCROLLBAR)

  def thumbnail_attrs(index)
    { type: "button",
      class: cn("block size-16 shrink-0  overflow-hidden rounded-md border-2 border-transparent opacity-70 hover:opacity-100",
                "aria-current:border-primary aria-current:opacity-100", UI::Base::FOCUS_RING),
      aria: { label: phrase(t("ui.gallery.thumbnail", default: "Show image %{current}"), current: index + 1),
              current: ("true" if index.zero?) }.compact,
      data: { action: "ui--gallery#select", "ui--gallery-index-param": index, "ui--gallery-target": "thumbnail" } }
  end

  def nav_button_attrs(direction)
    edge = direction == :previous ? "start-2" : "end-2"
    { variant: :outline, size: :icon,
      class: cn("absolute top-1/2 z-10 hidden -translate-y-1/2 rounded-full bg-background/90 sm:inline-flex", edge),
      aria: { label: nav_label(direction) }, data: { action: "ui--gallery##{direction}" } }
  end

  def overlay_nav_attrs(direction)
    edge = direction == :previous ? "start-4" : "end-4"
    { variant: :ghost, size: :icon,
      class: cn(OVERLAY_BUTTON, "absolute top-1/2 z-10 -translate-y-1/2", edge),
      aria: { label: nav_label(direction) }, data: { action: "ui--gallery##{direction}" } }
  end

  def zoom_button_attrs(direction, label)
    { variant: :ghost, size: :icon, class: OVERLAY_BUTTON,
      aria: { label: t("ui.gallery.zoom_#{direction}", default: label) },
      data: { action: "ui--gallery#zoom#{direction.to_s.capitalize}", "ui--gallery-target": "zoom#{direction.to_s.capitalize}" } }
  end

  def position_text = phrase(position_format, current: 1, total: images.size)

  private

  def nav_label(direction) = t("ui.gallery.#{direction}", default: "#{direction.to_s.capitalize} image")

  def slide_action
    return "ui--gallery#open" unless hover_zoom?

    "ui--gallery#open pointerenter->ui--gallery#hover pointermove->ui--gallery#hover pointerleave->ui--gallery#hoverEnd"
  end

  def label = @label || t("ui.gallery.label", default: "Image gallery")
  def position_format = t("ui.gallery.position", default: "Image %{current} of %{total}")

  # Filled in here rather than by t(), so the controller can be handed the same
  # text with its placeholders still in it.
  def phrase(format, **values)
    values.reduce(format) { |text, (key, value)| text.sub("%{#{key}}", value.to_s) }
  end
end
