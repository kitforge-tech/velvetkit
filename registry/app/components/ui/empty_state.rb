# frozen_string_literal: true

# What a page shows in place of a list with nothing in it: an icon, a title,
# a line saying why, and the buttons that get someone started. The block is
# the actions row; `with_media` replaces the icon with an avatar, image or
# anything else.
#
# `variant: :outline` draws a dashed border, for an empty area inside a page
# rather than the whole page. `heading_level:` sets the title's <h1>–<h6> so
# it fits the page's outline (default 3).
class UI::EmptyState < UI::Base
  variants(
    base: "flex w-full flex-col items-center justify-center gap-6 rounded-lg p-6 text-center text-balance md:p-12",
    variants: {
      variant: {
        default: "",
        outline: "border border-dashed"
      }
    },
    defaults: { variant: :default }
  )

  renders_one :media

  def initialize(title: nil, description: nil, icon: nil, variant: :default, heading_level: 3,
                 class: nil, **html_attrs)
    @title         = title
    @description   = description
    @icon          = icon
    @variant       = variant
    @heading_level = heading_level.to_i.clamp(1, 6)
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
  end

  def classes
    cn(variant_classes(variant: @variant), @user_class)
  end

  def heading
    content_tag(:"h#{@heading_level}", @title, class: "text-lg font-semibold tracking-tight text-foreground")
  end

  def icon? = @icon.present?
  def header? = media? || icon? || @title.present? || @description.present?
end
