# frozen_string_literal: true

class UI::Dialog::Footer < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_content_context(_content_context); end

  def classes
    cn("flex flex-col-reverse gap-2 sm:flex-row sm:justify-end", @user_class)
  end
end
