# frozen_string_literal: true

class UI::Tooltip::Trigger < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_tooltip_context(tooltip)
    @tooltip = tooltip
    @id = @html_attrs[:id] || "ui-tooltip-trigger-#{tooltip.id}"
  end

  def classes
    cn(@user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id] = @id
    opts[:class] = classes
    opts[:type] = :button if opts[:as]&.to_sym == :button
    opts[:"aria-describedby"] = "ui-tooltip-content-#{@tooltip.id}"
    opts[:"data-ui--tooltip-target"] = "trigger"
    opts[:"data-action"] = [
      "mouseenter->ui--tooltip#show",
      "mouseleave->ui--tooltip#hide",
      "focus->ui--tooltip#show",
      "blur->ui--tooltip#hide"
    ].join(" ")
    opts
  end
end
