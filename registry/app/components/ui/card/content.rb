# frozen_string_literal: true

class UI::Card::Content < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("p-6 pt-0", @user_class)
  end
end
