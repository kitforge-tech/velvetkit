# Customers for the server-search demos of Select and Command on their docs
# pages. A real app
# searches its database; this searches a fixed list of 300, the way an app's
# endpoint would answer: matches only, by name, at most 20.
class DemoOptionsController < ApplicationController
  FIRST = %w[Aditi Arjun Chitra Dev Esha Farhan Gauri Harsh Isha Jai Kavya Lakshmi Manav Nisha Om Priya Rahul Sana Tanvi Vikram].freeze
  LAST = %w[Rao Nair Menon Shah Iyer Reddy Das Kapoor Joshi Pillai Bose Kulkarni Mehta Sethi Varma].freeze
  KINDS = [ "Traders", "Stores", "Kitchenware", "Home", "& Sons", "Supplies" ].freeze
  CUSTOMERS = 300.times.map do |i|
    { value: 2001 + i, label: "#{FIRST[i % FIRST.size]} #{LAST[(i * 7) % LAST.size]} #{KINDS[(i * 5) % KINDS.size]}" }
  end.uniq { _1[:label] }.sort_by { _1[:label] }.freeze

  def index
    render json: matching.first(20)
  end

  # The same customers for the Command's server search, in its shape: a label,
  # where to go, a line under it and the group to list it in. A few, since a
  # palette is for jumping, not browsing.
  def search
    return render json: [] if params[:q].to_s.strip.empty?

    render json: matching.first(6).map { |customer|
      { label: customer[:label], href: "#customer-#{customer[:value]}",
        description: "Customer ##{customer[:value]}", group: "Customers" }
    }
  end

  private

  def matching
    query = params[:q].to_s.strip.downcase
    query.empty? ? CUSTOMERS : CUSTOMERS.select { _1[:label].downcase.include?(query) }
  end
end
