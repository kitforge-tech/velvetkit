# frozen_string_literal: true

class UI::Accordion::Item < UI::Base
  renders_one :trigger, ->(**opts) {
    UI::Accordion::Trigger.new(content_id: "ui-accordion-content-#{@uid}", **opts)
  }
  renders_one :accordion_content, ->(**opts) {
    UI::Accordion::Content.new(trigger_id: "ui-accordion-trigger-#{@uid}", **opts)
  }

  alias_method :with_content, :with_accordion_content

  def initialize(value:, class: nil, **html_attrs)
    @uid        = SecureRandom.hex(6)
    @value      = value
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :value

  def set_accordion_context(accordion)
    @accordion_context = accordion
  end

  def classes
    cn("border-b last:border-b-0", @user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:class] = classes
    opts[:data]  = {
      "ui--accordion-target": "item",
      value: @value,
      state: "closed"
    }.merge(opts[:data] || {})
    opts
  end
end
