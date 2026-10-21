# frozen_string_literal: true

class UI::Breadcrumb::Item < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("inline-flex items-center gap-1.5 rounded", @user_class)
  end
end
