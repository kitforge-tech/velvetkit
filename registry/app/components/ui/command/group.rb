# frozen_string_literal: true

require "securerandom"

# A titled section of a UI::Command: "Pages", "Actions". Hidden while none of
# its items match what's typed.
class UI::Command::Group < UI::Base
  renders_many :items, "UI::Command::Item"

  def initialize(heading: nil, class: nil, **html_attrs)
    @heading    = heading
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @heading_id = "ui-command-group-#{SecureRandom.hex(4)}"
  end

  def call
    tag.div(role: "group", **@html_attrs, class: cn("py-1 [&:not(:first-child)]:border-t", @user_class),
            aria: { labelledby: (@heading_id if @heading) }.compact,
            data: { "ui--command-target": "group", **(@html_attrs[:data] || {}) }) do
      safe_join([
        (tag.div(@heading, id: @heading_id, class: "px-2 pt-1.5 pb-1 text-xs font-medium text-muted-foreground") if @heading),
        safe_join(items.map(&:to_s))
      ])
    end
  end
end
