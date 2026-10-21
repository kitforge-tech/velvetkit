# Rows for the DataGrid demo on its docs page. A real app answers the grid
# from its database; this answers from a fixed list, applying the same paging,
# sorting and filtering the grid asks for.
class DemoRowsController < ApplicationController
  FIRST = %w[Aditi Arjun Chitra Dev Esha Farhan Gauri Harsh Isha Jai Kavya Lakshmi Manav Nisha Om Priya Rahul Sana Tanvi Vikram].freeze
  LAST = %w[Rao Nair Menon Shah Iyer Reddy Das Kapoor Joshi Pillai].freeze
  PLANS = %w[Free Team Business Enterprise].freeze
  ROWS = 120.times.map do |i|
    { id: 1001 + i, name: "#{FIRST[i % FIRST.size]} #{LAST[(i * 7) % LAST.size]}",
      plan: PLANS[(i * 3) % PLANS.size], seats: 1 + (i * 37 % 60) }
  end.freeze

  def index
    rows = sorted(ROWS.select { |row| matches?(row) })
    first = params[:startRow].to_i
    last = params[:endRow].to_i.clamp(first, first + 100)
    render json: { rows: rows[first...last], total: rows.size }
  end

  private

  def matches?(row)
    filters.all? do |field, filter|
      value = row[field.to_sym]
      case filter["filterType"]
      when "number" then value == filter["filter"].to_i
      else value.to_s.downcase.include?(filter["filter"].to_s.downcase)
      end
    end
  end

  def sorted(rows)
    sort = JSON.parse(params[:sortModel].presence || "[]").first
    return rows unless sort && ROWS.first.key?(sort["colId"].to_sym)

    rows = rows.sort_by { |row| row[sort["colId"].to_sym] }
    sort["sort"] == "desc" ? rows.reverse : rows
  end

  def filters
    JSON.parse(params[:filterModel].presence || "{}").slice(*ROWS.first.keys.map(&:to_s))
  end
end
