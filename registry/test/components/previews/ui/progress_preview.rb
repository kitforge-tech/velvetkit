# frozen_string_literal: true

class UI::ProgressPreview < ViewComponent::Preview
  # @label Playground
  # @param value number
  # @param max number
  # @param indeterminate toggle "No value: shows work going on, without an amount"
  # @param label text
  # @param show_value toggle
  # @param value_text text "Can use %{value}, %{max} and %{percent}"
  # @param size select { choices: [sm, default, lg] }
  # @param tone select { choices: [default, success, warning, destructive] }
  def playground(value: 40, max: 100, indeterminate: false, label: "Uploading report.pdf", show_value: true,
                 value_text: "", size: :default, tone: :default)
    render(UI::Progress.new(value: (value unless indeterminate), max: max, label: label.presence,
                            show_value: show_value, value_text: value_text.presence, size: size.to_sym,
                            tone: tone.to_sym, class: "max-w-sm"))
  end

  # @label Sizes and Tones
  def sizes_and_tones; render_with_template; end

  # @label File Upload, Moving Live
  def file_upload; render_with_template; end

  # @label Storage Used
  def storage; render_with_template; end

  # @label Storage by Category
  def storage_by_category; render_with_template; end

  # @label Tasks by Status
  def tasks_by_status; render_with_template; end

  # @label Traffic by Source, Shares of a Whole
  def traffic_by_source; render_with_template; end

  # @label Steps Done
  def steps; render_with_template; end

  # @label Working, No Amount Yet
  def indeterminate; render_with_template; end

  # @label Free Shipping Threshold
  def free_shipping; render_with_template; end
end
