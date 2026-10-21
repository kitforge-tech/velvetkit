# frozen_string_literal: true

class UI::Typography::Small < UI::Text
  def initialize(class: nil, **html_attrs)
    super(as: :small, size: :xs, weight: :medium, tone: :default, class: binding.local_variable_get(:class), **html_attrs)
  end
end
