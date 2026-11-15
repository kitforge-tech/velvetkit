# frozen_string_literal: true

# A body row. In a table with `selection:`, `value:` is what its checkbox
# posts and `label:` names the row for it ("Select Acme").
class UI::Table::Row < UI::Base
  renders_many :cells, UI::Table::Cell

  def initialize(selected: false, value: nil, label: nil, selection: nil, form: nil, class: nil, **html_attrs)
    @selected   = selected
    @value      = value
    @label      = label
    @selection  = selection
    @form       = form
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def selectable? = @selection.present? && !@value.nil?
  def selection_column? = @selection.present?

  def select_box
    UI::SelectionBar.checkbox(:item, name: @selection, value: @value, form: @form, checked: @selected,
                                   label: t("ui.table.select_row", label: @label || @value, default: "Select %{label}"))
  end

  def classes
    cn("border-b border-border transition-colors hover:bg-muted/50",
       "has-[[data-selection=item]:checked]:bg-primary/5 has-[[data-selection=item]:checked]:hover:bg-primary/10",
       { "bg-muted" => @selected && !selection_column? }, @user_class)
  end

  def html_options
    opts = @html_attrs.dup
    opts[:class] = classes
    # aria-selected rather than colour alone, so the state is not conveyed by
    # appearance only. A row with a checkbox has that to say it instead.
    opts[:"aria-selected"] = "true" if @selected && !selection_column?
    opts
  end
end
