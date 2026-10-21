# frozen_string_literal: true

class UI::Breadcrumb::List < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("flex flex-wrap items-center gap-1.5 break-words sm:gap-2.5", @user_class)
  end
end
