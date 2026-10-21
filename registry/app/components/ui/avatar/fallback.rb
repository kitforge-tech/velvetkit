# frozen_string_literal: true

class UI::Avatar::Fallback < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("flex h-full w-full items-center justify-center font-medium", @user_class)
  end
end
