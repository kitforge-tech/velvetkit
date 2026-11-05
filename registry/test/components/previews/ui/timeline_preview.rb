# frozen_string_literal: true

class UI::TimelinePreview < ViewComponent::Preview
  # @label Playground
  # @param variant select { choices: [default, dot, colored] }
  # @param status select { choices: [complete, current, upcoming, error] }
  # @param descriptions toggle
  def playground(variant: :default, status: :current, descriptions: true)
    render(UI::Timeline.new(variant: variant.to_sym, label: "Order history", class: "max-w-md")) do |timeline|
      timeline.with_item(title: "Order placed", time: "Nov 3, 9:12 am",
                         description: ("Paid by card ending 4242" if descriptions))
      timeline.with_item(title: "Packed", time: "Nov 4, 2:40 pm",
                         description: ("Two boxes, 3.2 kg" if descriptions))
      timeline.with_item(title: "Out for delivery", status: status.to_sym, time: "Nov 5, 8:05 am",
                         description: ("With the courier" if descriptions))
      timeline.with_item(title: "Delivered", status: :upcoming, time: "Expected today")
    end
  end

  # @label Order Status
  def order_status; render_with_template; end

  # @label With a Failed Step
  def failed_delivery; render_with_template; end

  # @label Stock History
  def stock_history; render_with_template; end

  # @label Activity Log, with Dots
  def activity_log; render_with_template; end

  # @label Colored
  def colored; render_with_template; end

  # @label Colors That Mean Something
  def colored_by_meaning; render_with_template; end

  # @label Real Dates
  def real_dates; render_with_template; end
end
