module Helio
  # One visitor's copy of Helio: the changes they've made to customers (a
  # plan changed, a trial extended, a subscription cancelled) and the notes
  # they've left. Kept in their session, so nobody else sees them.
  class Workspace
    NOTE_LIMIT = 5

    def initialize(session)
      @state = session[:helio] ||= {}
    end

    def customers = Customer.all.map { |customer| apply(customer) }
    def customer(id) = (found = Customer.find(id)) && apply(found)

    def trial_ends_on(customer) = customer.trial_ends_on(extended_by: extensions[customer.id.to_s].to_i)

    def change_plan(customer, plan)
      return false unless Customer::PLANS.key?(plan)

      write("plans", customer, plan)
    end

    def extend_trial(customers, days: 14)
      customers.select { |customer| customer.status == "trialing" }.each do |customer|
        write("extensions", customer, extensions[customer.id.to_s].to_i + days)
      end
    end

    def cancel(customers) = customers.reject { |c| c.status == "cancelled" }.each { |customer| write("statuses", customer, "cancelled") }
    def reactivate(customer) = write("statuses", customer, "active")

    def notes(customer) = (@state.dig("notes", customer.id.to_s) || []).map { |text, at| { text:, at: Time.zone.parse(at) } }

    def add_note(customer, text)
      list = ((@state["notes"] ||= {})[customer.id.to_s] ||= [])
      list.unshift([ text, Time.current.iso8601 ])
      list.pop while list.size > NOTE_LIMIT
    end

    private

    def extensions = @state["extensions"] || {}

    def apply(customer)
      changes = {}
      changes[:status] = @state.dig("statuses", customer.id.to_s) if @state.dig("statuses", customer.id.to_s)
      changes[:plan] = @state.dig("plans", customer.id.to_s) if @state.dig("plans", customer.id.to_s)
      changes[:last_active_on] = Customer::TODAY if changes[:status] == "cancelled" && customer.status != "cancelled"
      changes.empty? ? customer : customer.with(**changes)
    end

    def write(key, customer, value)
      (@state[key] ||= {})[customer.id.to_s] = value
    end
  end
end
