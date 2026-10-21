# frozen_string_literal: true

class UI::Card::Title < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("text-lg font-semibold leading-none tracking-tight", @user_class)
  end
end
