# frozen_string_literal: true

class UI::Typography::H1 < UI::Text
  def initialize(class: nil, **html_attrs)
    super(as: :h1, size: :"4xl", weight: :bold, tone: :default, class: binding.local_variable_get(:class), **html_attrs)
  end
end
