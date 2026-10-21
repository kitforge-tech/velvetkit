# frozen_string_literal: true

class UI::Tabs::Trigger < UI::Base
  variants(
    base: "inline-flex items-center justify-center gap-2 whitespace-nowrap " \
          "font-medium transition-all " \
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1 " \
          "disabled:pointer-events-none disabled:bg-muted! disabled:text-muted-foreground!",
    variants: {
      variant: {
        line:  "relative -mb-px px-3 text-muted-foreground hover:text-foreground " \
               "data-[state=active]:text-foreground data-[state=active]:border-b-2 data-[state=active]:border-primary",
        pill:  "px-3 rounded-sm text-muted-foreground hover:text-foreground " \
               "data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm",
        solid: "px-4 text-muted-foreground hover:text-foreground first:rounded-l-md last:rounded-r-md " \
               "data-[state=active]:bg-primary data-[state=active]:text-primary-foreground"
      },
      size: {
        sm:      "text-xs",
        default: "text-sm",
        lg:      "text-base"
      }
    },
    compound: [
      # Line variant heights
      { when: { variant: :line, size: :sm },      class: "h-8" },
      { when: { variant: :line, size: :default }, class: "h-10" },
      { when: { variant: :line, size: :lg },      class: "h-11" },
      # Pill variant heights
      { when: { variant: :pill, size: :sm },      class: "h-7" },
      { when: { variant: :pill, size: :default }, class: "h-8" },
      { when: { variant: :pill, size: :lg },      class: "h-9" },
      # Solid variant heights
      { when: { variant: :solid, size: :sm },      class: "h-8" },
      { when: { variant: :solid, size: :default }, class: "h-10" },
      { when: { variant: :solid, size: :lg },      class: "h-11" }
    ],
    defaults: { variant: :line, size: :default }
  )

  renders_one :leading_icon, ->(name:, **opts) {
    UI::Icon.new(name: name, size: opts.delete(:size) || :sm, **opts)
  }

  def initialize(value:, disabled: false, class: nil, **html_attrs)
    @value      = value
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :value

  def set_tab_context(tabs, list:)
    @tab_context = tabs
    @list        = list
    @id          = @html_attrs[:id] || "ui-tab-#{tabs.id}-#{@value}"
  end

  def panel_id
    "ui-panel-#{@tab_context.id}-#{@value}"
  end

  def active?
    @tab_context.initial_value.to_s == @value.to_s
  end

  def classes
    cn(
      variant_classes(variant: @tab_context.variant, size: @tab_context.size),
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:type]              = :button
    opts[:role]              = :tab
    opts[:id]                = @id
    opts[:class]             = classes
    opts[:disabled]          = true if @disabled
    opts[:"aria-selected"]   = active? ? "true" : "false"
    opts[:"aria-controls"]   = panel_id
    opts[:tabindex]          = active? ? "0" : "-1"
    opts[:"data-state"]      = active? ? "active" : "inactive"
    opts[:"data-ui--tabs-target"] = "trigger"
    opts[:"data-value"]      = @value.to_s
    opts[:"data-action"]     = "click->ui--tabs#activate keydown->ui--tabs#keydown"
    opts
  end
end
