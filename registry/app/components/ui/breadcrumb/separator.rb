# frozen_string_literal: true

class UI::Breadcrumb::Separator < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("text-muted-foreground/70", @user_class)
  end
end
