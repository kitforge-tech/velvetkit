# frozen_string_literal: true

class UI::Tabs::List < UI::Base
  renders_many :triggers, ->(value:, **opts) {
    UI::Tabs::Trigger.new(value: value, **opts).tap { |t| t.set_tab_context(@tab_context, list: self) }
  }

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_tab_context(tabs); @tab_context = tabs; end

  def first_trigger_value
    triggers.first&.value
  end

  def classes
    cn(LIST_VARIANT[@tab_context&.variant || :line], @user_class)
  end

  LIST_VARIANT = {
    line:  "inline-flex items-center gap-4 border-b border-input",
    pill:  "inline-flex items-center gap-1 rounded-md bg-muted p-1",
    solid: "inline-flex items-center rounded-md border border-input divide-x divide-input bg-background"
  }.freeze
end
