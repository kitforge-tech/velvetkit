# frozen_string_literal: true

class UI::Accordion::Trigger < UI::Base
  def initialize(content_id: nil, disabled: false, class: nil, **html_attrs)
    @content_id = content_id
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(
      "group flex w-full items-center gap-3 py-2 text-sm font-medium transition-all hover:underline text-left text-primary",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1 rounded",
      "disabled:pointer-events-none disabled:opacity-50",
      UI::Base::FOCUS_RING,
      @user_class
    )
  end

  def trigger_id
    @html_attrs[:id] || "ui-accordion-trigger-#{SecureRandom.hex(4)}"
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id]               = trigger_id
    opts[:class]            = classes
    opts[:type]             = :button
    opts[:"aria-expanded"]  = "false"
    opts[:"aria-controls"]  = @content_id if @content_id
    opts[:"data-ui--accordion-target"] = "trigger"
    opts[:"data-action"]    = "click->ui--accordion#toggle keydown->ui--accordion#keydown"
    opts[:disabled]         = true if @disabled
    opts
  end
end
