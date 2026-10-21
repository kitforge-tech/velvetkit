# frozen_string_literal: true

class UI::Breadcrumb < UI::Base
  SEPARATOR_COLOR = "text-muted-foreground/70".freeze
  SIZES = { sm: "text-xs", md: "text-sm" }.freeze
  COLLAPSE_POSITIONS = %i[start middle end].freeze

  renders_many :items, ->(href:, text:, avatar_src: nil, current: false, **opts) {
    UI::Breadcrumb::ItemSlot.new(href: href, text: text, avatar_src: avatar_src, current: current, **opts)
  }
  # Deprecated: explicit ellipsis slot will be replaced by auto-ellipsis
  renders_one :ellipsis, UI::Breadcrumb::Ellipsis

  def initialize(size: :sm, separator_icon: :slash, max_items: nil, collapse_at: :middle, class: nil, **html_attrs)
    @size = size
    @separator_icon = separator_icon
    @max_items = max_items
    @collapse_at = collapse_at
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def before_render
    items.each_with_index do |item, idx|
      item.set_context(idx, items.length, @size)
    end
  end

  def classes
    cn(SIZES[@size], @user_class)
  end

  def separator_classes
    cn(
      SEPARATOR_COLOR,
      @size == :md ? "text-sm" : "text-xs"
    )
  end

  def auto_collapse?
    @max_items && items.length > @max_items
  end

  # The last item (current page) is always preserved.
  # Remaining budget = max_items - 1 is distributed across the prefix.
  def visible_items
    return items unless auto_collapse?

    current = [ items.last ]
    budget = @max_items - 1
    prefix = items[0...-1]

    case @collapse_at
    when :start
      prefix.last([ budget, 0 ].max) + current
    when :end
      prefix.first([ budget, 0 ].max) + current
    when :middle
      head_count = [ (budget / 2.0).ceil, prefix.length ].min
      tail_count = [ budget - head_count, prefix.length - head_count ].min
      tail_count = [ tail_count, 0 ].max
      prefix.first(head_count) + prefix.last(tail_count) + current
    else
      items
    end
  end

  def hidden_items
    return [] unless auto_collapse?

    visible_set = visible_items.to_set
    items.reject { |item| visible_set.include?(item) }
  end

  def show_separator_after?(idx, collection = items)
    return false if idx == collection.length - 1
    true
  end

  def has_items?
    items.any?
  end
end
