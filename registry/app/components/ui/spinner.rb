# frozen_string_literal: true

class UI::Spinner < UI::Base
  def initialize(size: :default, label: nil, class: nil, **html_attrs)
    @size = size
    @label = label
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def icon
    UI::Icon.new(
      name: "loader",
      size: @size,
      aria: { hidden: true },
      class: cn("animate-spin", @user_class),
      **@html_attrs
    )
  end
end
