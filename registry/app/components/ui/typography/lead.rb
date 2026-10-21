# frozen_string_literal: true

class UI::Typography::Lead < UI::Text
  def initialize(class: nil, **html_attrs)
    super(as: :p, size: :xl, weight: :normal, tone: :muted, class: binding.local_variable_get(:class), **html_attrs)
  end
end
