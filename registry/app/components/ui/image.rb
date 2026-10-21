# frozen_string_literal: true

# UI::Image — asset-backed <img> with radius tokens and lazy loading.
#
# Replaces Velvet::Image, which wrapped every image in a Velvet::Box and passed
# `width:`/`height:` to that wrapper as inline styles — so the div was sized and
# the image itself was not. Here the dimensions land on the <img>.
#
# Usage:
#   <%= render(UI::Image.new(src: "logo.png", rounded: :lg, width: "100px")) %>
class UI::Image < UI::Base
  variants(
    base: "block max-w-full",
    variants: {
      rounded: {
        none: "rounded-none",
        xs:   "rounded-xs",
        sm:   "rounded-sm",
        md:   "rounded-md",
        lg:   "rounded-lg",
        xl:   "rounded-xl",
        full: "rounded-full"
      }
    },
    defaults: { rounded: :sm }
  )

  def initialize(src:, rounded: :sm, width: nil, height: nil, alt: nil,
                 loading: :lazy, class: nil, **html_attrs)
    @src        = src
    @rounded    = rounded
    @width      = width
    @height     = height
    @alt        = alt
    @loading    = loading
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(variant_classes(rounded: @rounded), @user_class)
  end

  # Dimensions arrive as CSS strings ("100px", "14px"), so they go through
  # `style` rather than the width/height attributes (which take bare pixels) or
  # an interpolated Tailwind class (which the scanner cannot see).
  def html_options
    opts = @html_attrs.dup
    opts[:src]     = asset_path(@src)
    opts[:class]   = classes
    opts[:alt]     = @alt || default_alt
    opts[:loading] = @loading if @loading

    dimensions = []
    dimensions << "width: #{css_length(@width)}"   if @width.present?
    dimensions << "height: #{css_length(@height)}" if @height.present?
    unless dimensions.empty?
      opts[:style] = [ dimensions.join("; "), opts[:style] ].compact.join("; ")
    end

    opts
  end

  private

  def css_length(value)
    value.is_a?(Numeric) ? "#{value}px" : value
  end

  # Mirrors image_tag's behaviour so alt text does not regress to empty.
  def default_alt
    File.basename(@src.to_s, ".*").tr("-_", "  ").capitalize
  end
end
