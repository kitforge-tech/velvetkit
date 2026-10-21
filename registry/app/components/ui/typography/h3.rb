# frozen_string_literal: true

class UI::Typography::H3 < UI::Text
  def initialize(class: nil, **html_attrs)
    super(as: :h3, size: :"2xl", weight: :semibold, tone: :default, class: binding.local_variable_get(:class), **html_attrs)
  end
end
