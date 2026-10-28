# frozen_string_literal: true

# "On this page" navigation with scrollspy. As the reader scrolls, the link to
# the section they are reading is marked current (aria-current="location") and
# an indicator slides beside it. A link jumps to its section like any anchor.
#
# Each item links to an element id on the page, and items nest:
#
#   <%= render(UI::TableOfContents.new(title: "On this page")) do |toc| %>
#     <% toc.with_item(href: "#install", text: "Install") do |item| %>
#       <% item.with_item(href: "#requirements", text: "Requirements") %>
#     <% end %>
#     <% toc.with_item(href: "#usage", text: "Usage") %>
#   <% end %>
#
# A section counts as reached once its top passes `offset:` pixels below the
# top of the scroll area; raise it to clear a sticky header. When the content
# scrolls inside an element rather than the window, pass that element's CSS
# selector as `container:`.
class UI::TableOfContents < UI::Base
  renders_many :items, ->(href:, text:, **opts) {
    UI::TableOfContents::Item.new(href: href, text: text, depth: 0, **opts)
  }

  def initialize(title: nil, label: nil, offset: 80, container: nil, class: nil, **html_attrs)
    @title      = title
    @label      = label
    @offset     = offset
    @container  = container
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id         = @html_attrs[:id] || "ui-toc-#{SecureRandom.hex(4)}"
    @html_attrs[:id] = @id
  end

  def title_id = "#{@id}-title"

  def html_options
    data = {
      controller: "ui--table-of-contents",
      "ui--table-of-contents-offset-value": @offset,
      "ui--table-of-contents-container-value": @container
    }.compact

    opts = @html_attrs.except(:data)
    opts[:class] = cn("text-sm", @user_class)
    opts[:data]  = data.merge(@html_attrs[:data] || {})
    if @title
      opts[:"aria-labelledby"] = title_id
    else
      opts[:"aria-label"] = @label || I18n.t("ui.table_of_contents.label", default: "On this page")
    end
    opts
  end
end
