# frozen_string_literal: true

class UI::Accordion::Content < UI::Base
  def initialize(trigger_id: nil, class: nil, **html_attrs)
    @trigger_id = trigger_id
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def wrapper_classes
    cn(
      "grid grid-rows-[0fr] transition-[grid-template-rows] duration-200",
      "data-[state=open]:grid-rows-[1fr]",
      @user_class
    )
  end

  def content_id
    @html_attrs[:id] || "ui-accordion-content-#{SecureRandom.hex(4)}"
  end

  def html_options
    opts = @html_attrs.dup
    opts[:id]    = content_id
    opts[:role]  = "region"
    opts[:class] = wrapper_classes
    opts[:"aria-labelledby"] = @trigger_id if @trigger_id
    opts[:data]  = {
      "ui--accordion-target": "content",
      state: "closed"
    }.merge(opts[:data] || {})
    opts
  end
end
