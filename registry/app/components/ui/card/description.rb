# frozen_string_literal: true

class UI::Card::Description < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("text-sm text-muted-foreground", @user_class)
  end
end
