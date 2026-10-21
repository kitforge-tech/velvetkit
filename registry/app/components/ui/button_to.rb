# frozen_string_literal: true

# UI::ButtonTo — a UI::Button rendered inside a real form via Rails' `button_to`.
#
# Use when the action is a non-GET request (sign-in with a provider, destroy,
# any state change) rather than navigation. Inherits UI::Button's variants,
# sizes and icon slots so the two stay visually identical.
#
# Velvet::ButtonTo inherited Button's icon/loading slots but its template never
# rendered them; this one does.
#
# Usage:
#   <%= render(UI::ButtonTo.new(sign_out_path, method: :delete, variant: :outline)) do %>
#     Sign out
#   <% end %>
class UI::ButtonTo < UI::Button
  def initialize(path, form_class: nil, **args)
    @path       = path
    @form_class = form_class
    super(**args)
  end

  # `button_to` splits its options: everything here decorates the <button>,
  # while form-level concerns (method, params, form_class) stay on the form.
  def button_options
    opts = @html_attrs.dup
    opts[:class]      = classes
    opts[:disabled]   = true if effective_disabled?
    opts[:form_class] = @form_class if @form_class
    opts[:"aria-busy"] = "true" if @loading
    opts
  end
end
