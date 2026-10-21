# frozen_string_literal: true

class UI::Menu::Group < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(@user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:class] = classes
    opts[:role] = :group
    opts
  end
end
