# frozen_string_literal: true

# A header cell. Renders <th scope="col"> so assistive technology announces it
# as a header rather than as data.
class UI::Table::Column < UI::Base
  ALIGNMENTS = { start: "text-left", center: "text-center", end: "text-right" }.freeze

  def initialize(align: :start, class: nil, **html_attrs)
    @align      = align
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("h-10 px-2 align-middle font-medium text-foreground whitespace-nowrap",
       ALIGNMENTS.fetch(@align, ALIGNMENTS[:start]), @user_class)
  end
end
