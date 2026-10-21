# frozen_string_literal: true

# UI::Pagination — page links for a long list.
#
# Follows shadcn's structure (nav > ul > li > a, ghost links with the current
# page outlined) and takes a Pagy::Offset, so controllers stay conventional.
#
# The series is computed here rather than read from Pagy, whose own #series is
# protected in v43 and whose gap marker differs by version.
#
# Usage:
#   <%= render(UI::Pagination.new(pagy: @pagy) { |page| section_path(@section, page: page) }) %>
class UI::Pagination < UI::Base
  GAP = :gap

  # How many pages either side of the current one to show before collapsing.
  WINDOW = 2

  def initialize(pagy:, label: nil, class: nil, **html_attrs, &url_builder)
    @pagy = pagy
    @label = label
    @url_builder = url_builder
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :pagy

  # One page of results needs no controls.
  def render? = pagy.present? && pagy.pages > 1

  def classes = cn("mx-auto flex w-full justify-center", @user_class)

  def label = @label || I18n.t("ui.pagination.label", default: "Pagination")

  def url_for_page(page) = @url_builder ? @url_builder.call(page) : "?page=#{page}"

  def current?(page) = page == pagy.page

  # First and last are always shown so the ends stay reachable; the rest is a
  # window around the current page, with gaps collapsed.
  def series
    return (1..pagy.pages).to_a if pagy.pages <= (WINDOW * 2) + 5

    window = ((pagy.page - WINDOW)..(pagy.page + WINDOW)).select { |p| p.between?(1, pagy.pages) }
    pages = ([ 1 ] + window + [ pagy.pages ]).uniq.sort

    pages.each_with_object([]) do |page, out|
      out << GAP if out.last.is_a?(Integer) && page > out.last + 1
      out << page
    end
  end

  def previous_page = pagy.previous
  def next_page = pagy.next

  # "Showing 26–50 of 240" — more use to an office than page numbers alone.
  def summary
    I18n.t("ui.pagination.summary", from: pagy.from, to: pagy.to, count: pagy.count,
           default: "Showing %{from}–%{to} of %{count}")
  end
end
