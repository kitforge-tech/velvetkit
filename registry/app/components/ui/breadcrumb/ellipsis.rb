# frozen_string_literal: true

class UI::Breadcrumb::Ellipsis < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end
end
