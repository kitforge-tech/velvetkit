# frozen_string_literal: true

# The hint and error under a control, with the ids its aria-describedby names.
# For controls that lay out their own label, as UI::Select does.
class UI::FormField::Messages < UI::Base
  def initialize(field)
    @field = field
  end

  def render? = @field.hint.present? || @field.error_message.present?
end
