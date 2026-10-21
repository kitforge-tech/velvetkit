# frozen_string_literal: true

class UI::Tabs < UI::Base
  renders_one  :list, ->(**opts) { UI::Tabs::List.new(**opts).tap { |l| l.set_tab_context(self) } }
  renders_many :panels, ->(value:, **opts) { UI::Tabs::Content.new(value: value, **opts).tap { |p| p.set_tab_context(self) } }

  def initialize(default_value:, variant: :line, size: :default,
                 class: nil, **html_attrs)
    @default_value = default_value
    @variant       = variant
    @size          = size
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
    @id            = @html_attrs[:id] || "ui-tabs-#{SecureRandom.hex(4)}"
    @html_attrs[:id] = @id
  end

  attr_reader :variant, :size, :default_value, :id

  def root_classes
    cn("w-full", @user_class)
  end

  def initial_value
    @default_value || ""
  end
end
