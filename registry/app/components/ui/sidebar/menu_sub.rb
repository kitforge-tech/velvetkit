# frozen_string_literal: true

# Links under a sidebar menu item, indented beneath it, such as the albums
# under Albums. `name:` is the item's name, for the button that opens them.
#
#   <% item.with_sub_menu(name: "Albums") do |sub| %>
#     <% sub.with_item(album_path(album), active: current_page?(album_path(album))) { album.name } %>
#   <% end %>
class UI::Sidebar::MenuSub < UI::Base
  Item = Struct.new(:path, :active, :content, keyword_init: true)

  attr_reader :name

  def initialize(name: nil, class: nil, **html_attrs)
    @name = name
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @items = []
  end

  def with_item(path, active: false, &block)
    @items << Item.new(path: path, active: active, content: block)
    nil
  end

  def active? = @items.any?(&:active)

  # Set by the menu item before it draws this: the id its button points at,
  # and `open:` as given to the item (nil to follow the current page).
  def configure(id:, open:)
    @id = id
    @open = open
  end

  # Known once drawn, since the items are added as the block runs.
  def open? = @open.nil? ? active? : @open

  def call
    content # runs the block, which adds the items
    tag.ul(id: @id, hidden: !open?, data: { slot: "sidebar-menu-sub", sidebar: "menu-sub" },
           class: cn("ms-5 flex min-w-0 flex-col gap-0.5 border-s border-sidebar-border ps-2.5 py-0.5 group-data-[collapsible=icon]:hidden",
                     @user_class), **@html_attrs) do
      safe_join(@items.map { |item| tag.li(item_link(item)) })
    end
  end

  private

  def item_link(item)
    link_to(item.path, aria: { current: ("page" if item.active) },
                       data: { active: item.active.to_s },
                       class: "flex h-7 min-w-0 items-center gap-2 rounded-md px-2 text-sm text-sidebar-foreground/80 outline-hidden " \
                              "ring-sidebar-ring hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus:ring-2 " \
                              "data-[active=true]:bg-sidebar-accent data-[active=true]:font-medium data-[active=true]:text-sidebar-accent-foreground " \
                              "[&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0") do
      capture(&item.content)
    end
  end
end
