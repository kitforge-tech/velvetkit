# frozen_string_literal: true

class UI::Breadcrumb::ItemSlot < UI::Base
  def initialize(href:, text:, avatar_src: nil, current: false, **html_attrs)
    @href = href
    @text = text
    @avatar_src = avatar_src
    @is_current = current
    @html_attrs = html_attrs
  end

  def set_context(index, total, size)
    @index = index
    @total = total
    @size = size
  end

  def effective_current?
    @is_current || (@index == @total - 1)
  end

  def size_text_class
    UI::Breadcrumb::SIZES[@size]
  end

  def link_classes
    cn(
      size_text_class,
      effective_current? ? "text-foreground font-normal justify-start rounded" : "text-muted-foreground font-normal justify-start rounded"
    )
  end

  def link_options
    opts = @html_attrs.dup
    opts[:aria] = { current: "page" } if effective_current?
    opts[:data] = { breadcrumb_text: @text, breadcrumb_href: @href, breadcrumb_avatar: @avatar_src }.compact
    opts
  end

  def data_attrs
    attrs = { breadcrumb_text: @text, breadcrumb_href: @href, breadcrumb_avatar: @avatar_src }.compact
    attrs[:last] = "true" if effective_current?
    attrs
  end

  attr_reader :href, :text, :avatar_src
end
