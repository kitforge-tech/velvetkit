# frozen_string_literal: true

class UI::Tabs::Content < UI::Base
  attr_reader :value

  def initialize(value:, class: nil, **html_attrs)
    @value      = value
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_tab_context(tabs); @tab_context = tabs; end

  def panel_id
    "ui-panel-#{@tab_context.id}-#{@value}"
  end

  def trigger_id
    "ui-tab-#{@tab_context.id}-#{@value}"
  end

  def active?
    @tab_context.initial_value.to_s == @value.to_s
  end

  def classes
    cn("mt-2", @user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:role]                   = :tabpanel
    opts[:id]                     = panel_id
    opts[:class]                  = classes
    opts[:"aria-labelledby"]      = trigger_id
    opts[:tabindex]               = "0"
    opts[:"data-state"]           = active? ? "active" : "inactive"
    opts[:"data-ui--tabs-target"] = "panel"
    opts[:"data-value"]           = @value.to_s
    opts[:hidden]                 = true unless active?
    opts
  end
end
