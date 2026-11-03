# frozen_string_literal: true

# A styled replacement for the browser's confirm() box that Turbo shows for
# `data-turbo-confirm`. Render one in your layout and every link, form and
# button_to that already asks for confirmation uses it, with no other change:
#
#   <%= render(UI::ConfirmDialog.new) %>
#
#   <%= button_to "Delete", project_path(@project), method: :delete,
#         data: { turbo_confirm: "Delete this project?",
#                 confirm_description: "Its pages and files go too. This can't be undone.",
#                 confirm_button: "Delete project", confirm_variant: "destructive" } %>
#
# The confirm message is the dialog's title. Optional data attributes, on the
# same element as data-turbo-confirm, fill in the rest: `confirm-description`,
# `confirm-button` and `confirm-cancel` (the button labels), and
# `confirm-variant="destructive"` for a red confirm button.
#
# It's a native <dialog>: Escape and clicking outside cancel, focus is trapped
# inside and returns to the trigger, and Cancel has focus when it opens so a
# stray Enter never confirms.
class UI::ConfirmDialog < UI::Base
  PANEL = "relative flex w-full max-w-md flex-col gap-6 rounded-lg border bg-background p-6 shadow-lg " \
          "data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95"

  def initialize(confirm_label: nil, cancel_label: nil, class: nil, **html_attrs)
    @confirm_label = confirm_label
    @cancel_label  = cancel_label
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
    @id            = html_attrs[:id] || "ui-confirm-dialog"
  end

  def confirm_label = @confirm_label || t("ui.confirm_dialog.confirm", default: "Confirm")
  def cancel_label = @cancel_label || t("ui.confirm_dialog.cancel", default: "Cancel")
  def title_id = "#{@id}-title"
  def description_id = "#{@id}-description"

  def dialog_attrs
    attrs = @html_attrs.except(:data)
    attrs[:id] = @id
    attrs[:class] = cn(
      "fixed inset-0 m-0 h-full max-h-none w-full max-w-none border-0 bg-transparent p-4 overflow-visible " \
      "open:flex open:items-center open:justify-center backdrop:bg-black/60 backdrop:backdrop-blur-[1px]",
      @user_class
    )
    attrs[:aria] = { labelledby: title_id, describedby: description_id }
    attrs[:data] = {
      slot: "confirm-dialog", controller: "ui--confirm-dialog",
      "ui--confirm-dialog-confirm-label-value": confirm_label,
      "ui--confirm-dialog-cancel-label-value": cancel_label
    }.merge(@html_attrs[:data] || {})
    attrs
  end
end
