# frozen_string_literal: true

class UI::Card < UI::Base
  renders_one :header, UI::Card::Header
  renders_one :card_content, UI::Card::Content
  renders_one :footer, UI::Card::Footer

  alias_method :with_content, :with_card_content

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("rounded-xl border bg-card text-card-foreground shadow", @user_class)
  end
end
