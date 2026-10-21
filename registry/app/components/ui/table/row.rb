# frozen_string_literal: true

# A body row.
class UI::Table::Row < UI::Base
  renders_many :cells, UI::Table::Cell

  def initialize(selected: false, class: nil, **html_attrs)
    @selected   = selected
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("border-b border-border transition-colors hover:bg-muted/50",
       { "bg-muted" => @selected }, @user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:class] = classes
    # aria-selected rather than colour alone, so the state is not conveyed by
    # appearance only.
    opts[:"aria-selected"] = "true" if @selected
    opts
  end
end
