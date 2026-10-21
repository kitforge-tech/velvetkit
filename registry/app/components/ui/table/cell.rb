# frozen_string_literal: true

# A data cell.
class UI::Table::Cell < UI::Base
  def initialize(align: :start, class: nil, **html_attrs)
    @align      = align
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("p-2 align-middle",
       UI::Table::Column::ALIGNMENTS.fetch(@align, UI::Table::Column::ALIGNMENTS[:start]),
       @user_class)
  end
end
