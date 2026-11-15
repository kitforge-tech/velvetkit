module Helio
  class OverviewController < ApplicationController
    def show
      @range   = Metrics::RANGES.key?(params[:range]) ? params[:range] : "30d"
      @metrics = Metrics.new(range: @range, customers: workspace.customers)
    end
  end
end
