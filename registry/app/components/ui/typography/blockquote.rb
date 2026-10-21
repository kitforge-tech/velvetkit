# frozen_string_literal: true

class UI::Typography::Blockquote < UI::Base
  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn(
      "mt-6 border-l-2 border-border pl-6 italic text-foreground",
      @user_class
    )
  end
end
