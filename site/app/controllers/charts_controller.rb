# The Charts section: an overview of UI::Chart, then a page for each kind of
# chart it draws (line, bar, stacked bar, pie and donut), each with live examples.
class ChartsController < ApplicationController
  # In the order the sidebar lists them: title, then the summary and search
  # keywords for the search box and the page's meta description.
  PAGES = {
    "overview" => [ "Overview", "Line and bar charts for Rails: install, data, formats, colours, accessibility and animation.",
                    "chart charts graph graphs dashboard report chart.js data visualisation visualization" ],
    "line" => [ "Line chart", "Change over time: one series or several, with currency, percentages and gaps.",
                "line chart trend time series over time compare this year last year" ],
    "bar" => [ "Bar chart", "Compare amounts across categories, side by side, including values below zero.",
               "bar chart column chart compare categories grouped negative" ],
    "stacked_bar" => [ "Stacked bar chart", "Show how a total splits into its parts, day by day or month by month.",
                       "stacked bar chart parts of a whole breakdown split total" ],
    "pie" => [ "Pie chart", "One total split into a few parts at a glance, with each part's value and share.",
               "pie chart slices share percentage parts of a whole breakdown" ],
    "donut" => [ "Donut chart", "A pie with the total in its middle, for when the total matters as much as the split.",
                 "donut doughnut ring chart total slices share" ]
  }.freeze

  layout "docs"

  # The route only allows these pages, and the template is still taken from the
  # list rather than from the request.
  def show
    @chart_page = PAGES.keys.find { |page| page == params[:page] } or raise ActionController::RoutingError, "Not Found"
    render @chart_page
  end

  def self.path_for(page, routes = Rails.application.routes.url_helpers)
    page == "overview" ? routes.charts_path : routes.chart_doc_path(page)
  end
end
