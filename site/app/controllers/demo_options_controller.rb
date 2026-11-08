# Customers for the Select's server-search demo on its docs page. A real app
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
    query = params[:q].to_s.strip.downcase
    matches = query.empty? ? CUSTOMERS : CUSTOMERS.select { _1[:label].downcase.include?(query) }
    render json: matches.first(20)
  end
end
