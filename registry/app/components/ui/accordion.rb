# frozen_string_literal: true

class UI::Accordion < UI::Base
  renders_many :items, ->(value:, **opts) {
    UI::Accordion::Item.new(value: value, **opts).tap { |i| i.set_accordion_context(self) }
  }

  def initialize(type: :single, collapsible: true, default_value: nil,
                 class: nil, **html_attrs)
    @type          = type
    @collapsible   = collapsible
    @default_value = default_value
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
    @id            = @html_attrs[:id] || "ui-accordion-#{SecureRandom.hex(4)}"
    @html_attrs[:id] = @id
  end

  attr_reader :type, :collapsible, :default_value, :id

  def root_classes
    cn("w-full", @user_class)
  end

  def initial_values
    vals = case type
    when :single
             @default_value ? [ @default_value.to_s ] : []
    else
             Array(@default_value).map(&:to_s)
    end
    vals.to_json
  end
end
