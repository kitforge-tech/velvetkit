module Helio
  class CustomersController < ApplicationController
    VIEWS = { "all" => "All", "active" => "Active", "trialing" => "Trialing", "past_due" => "Past due", "cancelled" => "Cancelled" }.freeze
    SORTS = {
      "company" => ->(customer) { customer.company.downcase },
      "plan" => ->(customer) { Customer::PLANS.keys.index(customer.plan) },
      "seats" => :seats.to_proc,
      "mrr" => :mrr.to_proc,
      "signed_up" => :signed_up_on.to_proc,
      "last_active" => :last_active_on.to_proc
    }.freeze
    PER_PAGE = 20

    def index
      everyone = workspace.customers
      @counts = VIEWS.keys.to_h { |view| [ view, view == "all" ? everyone.size : everyone.count { |c| c.status == view } ] }
      @view = VIEWS.key?(params[:view]) ? params[:view] : "all"
      @query = params[:q].to_s.strip.first(60)
      @plan = Customer::PLANS.key?(params[:plan]) ? params[:plan] : nil
      @sort = SORTS.key?(params[:sort]) ? params[:sort] : "mrr"
      @dir = params[:dir] == "asc" ? "asc" : "desc"

      list = everyone
      list = list.select { |c| c.status == @view } unless @view == "all"
      list = list.select { |c| c.plan == @plan } if @plan
      list = list.select { |c| [ c.company, c.contact, c.email ].any? { |text| text.downcase.include?(@query.downcase) } } if @query.present?
      list = list.sort_by { |c| [ SORTS[@sort].call(c), c.id ] }
      list = list.reverse if @dir == "desc"

      respond_to do |format|
        format.html do
          @total = list.size
          pages = [ (list.size / PER_PAGE.to_f).ceil, 1 ].max
          @pagy = Pagy::Offset.new(count: list.size, page: params[:page].to_i.clamp(1, pages), limit: PER_PAGE)
          @customers = list[@pagy.offset, PER_PAGE] || []
        end
        format.csv do
          ids = Array(params[:ids]).map(&:to_i)
          list = list.select { |c| ids.include?(c.id) } if ids.any?
          send_data csv(list), filename: "helio-customers-#{Customer::TODAY.iso8601}.csv", type: "text/csv"
        end
      end
    end

    def show
      @customer = workspace.customer(params[:id]) or raise ActionController::RoutingError, "No customer #{params[:id]}"
      @notes = workspace.notes(@customer)
    end

    def update
      customer = workspace.customer(params[:id]) or raise ActionController::RoutingError, "No customer #{params[:id]}"
      notice = case params[:do]
      when "plan"
        workspace.change_plan(customer, params[:plan].to_s) ? "Moved #{customer.company} to #{params[:plan]}." : nil
      when "extend_trial"
        workspace.extend_trial([ customer ]).any? ? "Gave #{customer.company} 14 more days of trial." : nil
      when "cancel"
        workspace.cancel([ customer ]).any? ? "Cancelled #{customer.company}'s subscription." : nil
      when "reactivate"
        workspace.reactivate(customer) && "Reactivated #{customer.company}."
      end
      redirect_to customer_path(customer), notice ? { notice: } : { alert: "That didn't change anything." }
    end

    def bulk
      chosen = Array(params[:ids]).filter_map { |id| workspace.customer(id) }
      changed = case params[:do]
      when "extend_trial" then workspace.extend_trial(chosen)
      when "cancel" then workspace.cancel(chosen)
      else []
      end
      what = params[:do] == "cancel" ? "Cancelled" : "Extended the trial for"
      notice = changed.any? ? "#{what} #{helpers.pluralize(changed.size, 'customer')}." : "None of those could be changed."
      redirect_back fallback_location: customers_path, notice:
    end

    private

    def csv(customers)
      rows = [ %w[ID Company Contact Email Plan Status Seats MRR Country Signed\ up Last\ active] ]
      rows += customers.map do |c|
        [ c.id, c.company, c.contact, c.email, c.plan, c.status.humanize, c.seats, c.mrr, c.country, c.signed_up_on, c.last_active_on ]
      end
      rows.map { |row| row.map { |value| quote(value.to_s) }.join(",") }.join("\n") + "\n"
    end

    # Quoted when needed, and a leading = + - @ made harmless for spreadsheets.
    def quote(text)
      text = "'#{text}" if text.start_with?("=", "+", "-", "@")
      text.match?(/[",\n]/) ? %("#{text.gsub('"', '""')}") : text
    end
  end
end
