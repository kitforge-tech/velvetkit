# frozen_string_literal: true

class UI::Typography::H2 < UI::Text
  def initialize(class: nil, **html_attrs)
    super(as: :h2, size: :"3xl", weight: :semibold, tone: :default, class: binding.local_variable_get(:class), **html_attrs)
  end
end
