# frozen_string_literal: true

class UI::Popover < UI::Base
  renders_one :trigger, ->(**opts) {
    UI::Popover::Trigger.new(**opts).tap { |t| t.set_popover_context(self) }
  }
  renders_one :popover_content, ->(**opts) {
    UI::Popover::Content.new(**opts).tap { |c| c.set_popover_context(self) }
  }
  # Alias for more natural API: `with_content` instead of `with_popover_content`
  alias_method :with_content, :with_popover_content

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || "ui-popover-#{SecureRandom.hex(4)}"
  end

  attr_reader :id

  def root_classes
    cn("inline-block", @user_class)
  end
end
