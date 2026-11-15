# frozen_string_literal: true

# A header cell. Renders <th scope="col"> so assistive technology announces it
# as a header rather than as data.
#
# With `sort_href:` the header is a link that sorts by the column, and
# `sorted:` (:asc or :desc) says it's sorted that way now.
class UI::Table::Column < UI::Base
  ALIGNMENTS = { start: "text-left", center: "text-center", end: "text-right" }.freeze
  SORT_ICONS = { asc: "arrow-up", desc: "arrow-down", none: "chevrons-up-down" }.freeze

  def initialize(align: :start, sort_href: nil, sorted: nil, sticky: false, class: nil, **html_attrs)
    @align      = align
    @sort_href  = sort_href
    @sorted     = sorted&.to_sym
    @sticky     = sticky
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def sortable? = @sort_href.present?

  def sort_icon = SORT_ICONS.fetch(@sorted || :none, SORT_ICONS[:none])

  def th_attrs
    attrs = { scope: "col", class: classes, **@html_attrs }
    attrs[:"aria-sort"] = { asc: "ascending", desc: "descending" }[@sorted] if sortable? && @sorted
    attrs
  end

  def link_classes
    cn("-mx-2 inline-flex h-8 items-center gap-1.5 rounded-md px-2 hover:bg-accent hover:text-accent-foreground",
       { "flex-row-reverse" => @align == :end }, UI::Base::FOCUS_RING)
  end

  def icon_classes = cn("size-3.5", { "text-muted-foreground/60" => @sorted.nil? })

  def classes
    cn("h-10 px-2 align-middle font-medium text-foreground whitespace-nowrap",
       ALIGNMENTS.fetch(@align, ALIGNMENTS[:start]), { "sticky top-0 z-10 bg-muted" => @sticky }, @user_class)
  end
end
