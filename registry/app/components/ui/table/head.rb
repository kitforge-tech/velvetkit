# frozen_string_literal: true

# The header row of a UI::Table.
class UI::Table::Head < UI::Base
  renders_many :columns, UI::Table::Column

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes = cn("border-b border-border bg-muted/50", @user_class)
end
