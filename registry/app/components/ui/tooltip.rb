# frozen_string_literal: true

class UI::Tooltip < UI::Base
  renders_one :trigger, ->(**opts) {
    UI::Tooltip::Trigger.new(**opts).tap { |t| t.set_tooltip_context(self) }
  }
  renders_one :tooltip_content, ->(**opts) {
    UI::Tooltip::Content.new(**opts).tap { |c| c.set_tooltip_context(self) }
  }
  # Alias for more natural API: `with_content` instead of `with_tooltip_content`
  alias_method :with_content, :with_tooltip_content

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || "ui-tooltip-#{SecureRandom.hex(4)}"
  end

  attr_reader :id

  def root_classes
    cn("inline-block", @user_class)
  end
end
