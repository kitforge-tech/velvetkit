# frozen_string_literal: true

class UI::Typography::Large < UI::Text
  def initialize(class: nil, **html_attrs)
    super(as: :div, size: :lg, weight: :semibold, tone: :default, class: binding.local_variable_get(:class), **html_attrs)
  end
end
