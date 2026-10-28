# frozen_string_literal: true

class UI::TableOfContents::Item < UI::Base
  variants(
    base: "block rounded-md px-3 text-muted-foreground hover:text-foreground " \
          "data-[state=ancestor]:text-foreground " \
          "data-[state=active]:bg-muted data-[state=active]:font-medium data-[state=active]:text-foreground " \
          "#{FOCUS_RING}",
    variants: {
      level: {
        top:    "py-1.5",
        nested: "py-1"
      }
    },
    defaults: { level: :top }
  )

  renders_many :items, ->(href:, text:, **opts) {
    UI::TableOfContents::Item.new(href: href, text: text, depth: @depth + 1, **opts)
  }

  def initialize(href:, text:, depth: 0, class: nil, **html_attrs)
    @href       = href
    @text       = text
    @depth      = depth
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def link_options
    opts = @html_attrs.except(:data)
    opts[:href]  = @href
    opts[:class] = cn(variant_classes(level: @depth.zero? ? :top : :nested), @user_class)
    opts[:data]  = {
      state: "inactive",
      "ui--table-of-contents-target": "link",
      action: "click->ui--table-of-contents#select"
    }.merge(@html_attrs[:data] || {})
    opts
  end
end
