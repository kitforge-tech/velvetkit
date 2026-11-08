# frozen_string_literal: true

# One part of a UI::Progress that's split by category, like the photos in a
# storage bar. Drawn by UI::Progress, not on its own.
#
#   <% progress.with_segment(value: 6.4, label: "Photos") %>
#   <% progress.with_segment(value: 2, label: "Backups", color: 5, value_text: "2 GB, last night") %>
#
# `color:` is one of the kit's five chart colours, 1 to 5; segments take them
# in order otherwise. `class:` sets anything else, like a background of your own.
class UI::Progress::Segment < UI::Base
  attr_reader :label, :color, :user_class, :value_text

  def initialize(value:, label:, color: nil, value_text: nil, class: nil)
    @value      = value
    @label      = label
    @color      = color
    @value_text = value_text
    @user_class = binding.local_variable_get(:class)
  end

  def value = [ @value.to_f, 0 ].max

  def call = nil
end
