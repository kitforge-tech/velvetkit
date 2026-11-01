# frozen_string_literal: true

# UI::SessionTabs::Tab — one tab plus its options menu.
#
#   value:         stable identifier, sent with every event
#   href:          makes the tab a link; omit it for an event-only tab
#   active:        whether this is the current tab
#   rename:        true (event only) or a URL (PATCH, label as `rename_param`)
#   duplicate:     true or a URL (POST)
#   move:          true or a URL (PATCH, with the new 1-based `position`);
#                  makes the tab draggable (a grip handle shows on hover,
#                  and is what touch drags by) and adds Move left/right
#   close:         true or a URL (DELETE)
#   close_confirm: text asking the user to confirm before closing; nil closes
#                  straight away
#
# Extra html attributes (e.g. `data: { turbo_frame: "pane" }`) go on the tab
# element itself. `with_meta` adds small secondary text after the label;
# `with_menu_item` adds app-specific items above Close.
class UI::SessionTabs::Tab < UI::Base
  ACTIONS = %i[rename duplicate move close].freeze

  # The grip and the options button stay hidden until the tab is hovered,
  # focused (keyboard), has its menu open, or is being dragged — and are
  # always shown where there is no hover (touch screens). They slide in from
  # their own edge. Written out in full so Tailwind's scanner sees each class.
  REVEAL_OPACITY =
    "opacity-0 group-hover/tab:opacity-100 group-focus-within/tab:opacity-100 " \
    "group-data-[dragging]/tab:opacity-100 group-has-[[aria-expanded=true]]/tab:opacity-100 " \
    "[@media(hover:none)]:opacity-100"
  REVEAL_SLIDE =
    "group-hover/tab:translate-x-0 group-focus-within/tab:translate-x-0 " \
    "group-data-[dragging]/tab:translate-x-0 group-has-[[aria-expanded=true]]/tab:translate-x-0 " \
    "[@media(hover:none)]:translate-x-0"
  REVEAL_MOTION = "transition-[opacity,translate] duration-200 ease-out motion-reduce:transition-none"

  variants(
    base: "group/tab relative flex shrink-0 items-center rounded-t-md border border-b-0 " \
          "border-transparent bg-muted/60 text-muted-foreground transition-colors " \
          "hover:border-primary/20 hover:bg-primary/5 hover:text-foreground " \
          "data-[state=active]:border-border data-[state=active]:bg-background " \
          "data-[state=active]:text-foreground " \
          "data-[dragging]:z-10 data-[dragging]:border-border data-[dragging]:bg-background " \
          "data-[dragging]:shadow-md data-[dragging]:transition-none",
    variants: {
      size: {
        default: "h-9",
        touch:   "h-11"
      }
    },
    defaults: { size: :default }
  )

  renders_one :meta

  def initialize(value:, href: nil, active: false, rename: false, duplicate: false,
                 move: false, close: false, close_confirm: nil, class: nil, **html_attrs)
    @value         = value.to_s
    @href          = href
    @active        = active
    @actions       = { rename: rename, duplicate: duplicate, move: move, close: close }
    @close_confirm = close_confirm
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
    @menu_items    = []
  end

  attr_reader :value, :menu_items

  def set_session_tabs_context(tabs)
    @tabs = tabs
  end

  # App-specific menu items, rendered above Close. Same arguments as
  # UI::Menu::Content#with_item.
  def with_menu_item(label = nil, **opts, &block)
    @menu_items << [ label, opts, block ]
    self
  end

  def active?
    @active
  end

  def link?
    @href.present?
  end

  def enabled?(action)
    @actions[action].present?
  end

  def any_menu?
    ACTIONS.any? { |a| enabled?(a) } || @menu_items.any?
  end

  # Close stays rendered (so the controller can bring it back) but is hidden
  # while the bar is down to its minimum number of tabs.
  def close_available?
    @tabs.closable_count?
  end

  def movable?
    enabled?(:move)
  end

  def can_move_left?;  @tabs.movable_neighbour?(self, -1); end
  def can_move_right?; @tabs.movable_neighbour?(self, 1);  end

  def size; @tabs.size; end

  def dom_key
    @value.parameterize.presence || Digest::SHA1.hexdigest(@value)[0, 8]
  end

  def trigger_id; "#{@tabs.id}-tab-#{dom_key}";         end
  def label_id;   "#{@tabs.id}-tab-#{dom_key}-label";   end

  def wrapper_classes
    cn(variant_classes(size: size), @user_class)
  end

  def wrapper_options
    data = {
      "ui--session-tabs-target": "tab",
      value: @value,
      state: active? ? "active" : "inactive"
    }
    ACTIONS.each do |action|
      url = @actions[action]
      data[:"#{action}_url"] = url if url.is_a?(String)
      data[:"#{action}_enabled"] = true if enabled?(action)
    end
    data[:close_confirm] = @close_confirm if @close_confirm.present?
    { role: "presentation", class: wrapper_classes, data: data }
  end

  def trigger_classes
    cn(
      "flex h-full min-w-0 items-center gap-2 rounded-t-md pl-3 text-sm font-medium outline-none",
      # Long-press opens our menu, not the browser's link callout.
      "select-none [-webkit-touch-callout:none]",
      "focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset",
      any_menu? ? "pr-1" : "pr-3",
      { "pl-4 text-base" => size == :touch },
      { "pl-0.5" => movable? }
    )
  end

  def trigger_options
    user_data = @html_attrs[:data] || {}
    opts = @html_attrs.except(:data)
    opts[:id]              = trigger_id
    opts[:role]            = "tab"
    opts[:class]           = trigger_classes
    opts[:"aria-selected"] = active? ? "true" : "false"
    opts[:"aria-current"]  = "page" if link? && active?
    opts[:tabindex]        = active? ? "0" : "-1"
    # A native link drag would cancel our pointer events mid-reorder.
    opts[:draggable]       = "false"
    opts[:data] = user_data.merge(
      "ui--session-tabs-target": "trigger",
      action: [
        user_data[:action],
        "click->ui--session-tabs#select",
        "keydown->ui--session-tabs#keydown",
        "contextmenu->ui--session-tabs#contextMenu",
        "pointerdown->ui--session-tabs#pressStart"
      ].compact.join(" ")
    )
    if link?
      opts[:href] = @href
    else
      opts[:type] = "button"
    end
    opts
  end

  # The grip is the only place a drag starts. `touch-none` lets a finger drag
  # it straight away instead of scrolling the tab list; the rest of the tab
  # still scrolls, selects, and long-presses for the menu. Not focusable:
  # Move left/right in the menu is the keyboard path.
  def handle_options
    {
      class: cn(
        "flex h-full shrink-0 cursor-grab touch-none select-none items-center justify-center overflow-hidden " \
        "rounded-tl-md text-muted-foreground hover:text-primary active:cursor-grabbing",
        size == :touch ? "w-7 pl-1" : "w-5 pl-1"
      ),
      "aria-hidden": "true",
      data: {
        "ui--session-tabs-target": "handle",
        action: "pointerdown->ui--session-tabs#dragStart"
      }
    }
  end

  # Slides in from the left.
  def handle_icon_classes
    cn(REVEAL_MOTION, REVEAL_OPACITY, "-translate-x-2", REVEAL_SLIDE)
  end

  # The button fades (so its hover background never shows half-way); the
  # icon inside slides in from the right.
  def menu_trigger_classes
    cn(
      "mr-1 overflow-hidden text-muted-foreground hover:bg-primary/10 hover:text-primary " \
      "aria-expanded:bg-primary/10 aria-expanded:text-primary",
      size == :touch ? "size-7" : "size-6",
      REVEAL_MOTION, REVEAL_OPACITY
    )
  end

  def menu_icon_classes
    cn(REVEAL_MOTION, "translate-x-2", REVEAL_SLIDE)
  end

  def menu_trigger_options
    {
      variant: :ghost,
      size: :icon_sm,
      class: menu_trigger_classes,
      tabindex: active? ? "0" : "-1",
      "aria-label": t("ui.session_tabs.options", default: "Tab options"),
      "aria-describedby": label_id,
      data: { "ui--session-tabs-target": "menuTrigger" }
    }
  end

  def menu_icon_size
    size == :touch ? :sm : :xs
  end

  def action_item_options(action, extra = {})
    { data: { action: "click->ui--session-tabs##{action}" }.merge(extra) }
  end

  # Hidden menu items must also be disabled, or UI::Menu's arrow-key
  # navigation would still try to focus them.
  def hidden_item_options(hidden)
    hidden ? { hidden: true, disabled: true } : {}
  end
end
