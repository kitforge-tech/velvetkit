# frozen_string_literal: true

class UI::Menu::Separator < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("-mx-1 h-px bg-muted", @user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:class] = classes
    opts[:role] = :separator
    opts[:"aria-orientation"] = :horizontal
    opts
  end
end
