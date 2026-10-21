# frozen_string_literal: true

class UI::RadioGroup < UI::Base
  renders_many :items, ->(value:, **opts) {
    item = UI::RadioGroup::Item.new(value: value, **opts)
    item.set_group_context(self)
    item
  }

  def initialize(name: nil, value: nil, size: :default,
                 required: false, disabled: false,
                 class: nil, **html_attrs)
    @name       = name
    @value      = value
    @size       = size
    @required   = required
    @disabled   = disabled
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("flex flex-col gap-2", @user_class)
  end

  def group_id
    @html_attrs[:id] || "ui-rg-#{SecureRandom.hex(4)}"
  end

  def required?;  @required; end
  def disabled?;  @disabled; end
  def name;       @name;     end
  def value;      @value;    end
  def size;       @size;     end
end
