# frozen_string_literal: true

class UI::Card::Header < UI::Base
  renders_one :title, UI::Card::Title
  renders_one :description, UI::Card::Description

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("flex flex-col gap-1.5 p-6", @user_class)
  end
end
