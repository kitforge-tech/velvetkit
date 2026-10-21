# frozen_string_literal: true

# UI::Dialog::Trigger — click-to-open wrapper.
#
# By default renders a UI::Button so variant/size styling works out of the
# box. Pass as: :a (or any other tag name) to fall back to a plain tag.
class UI::Dialog::Trigger < UI::Base
  def initialize(as: :button, variant: :default, size: :default,
                 class: nil, **html_attrs)
    @as         = as.to_sym
    @variant    = variant
    @size       = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_dialog_context(dialog)
    @dialog = dialog
  end

  # ── Options passed to UI::Button (when @as == :button) ───────────────────

  def button_options
    opts = @html_attrs.deep_dup
    opts[:variant] = @variant
    opts[:size]    = @size
    opts[:type]    = :button
    opts[:class]   = cn(@user_class)
    opts[:data]    = merged_data
    opts[:aria]    = merged_aria
    opts
  end

  # ── Options passed to tag.public_send (when @as != :button) ──────────────

  def html_options
    opts = @html_attrs.dup
    opts[:class] = cn(@user_class)

    user_data = (opts.delete(:data) || {}).dup
    user_action = user_data.delete(:action) || user_data.delete("action")
    opts[:data] = user_data.merge(
      "ui--dialog-target": "trigger",
      action: [ user_action, "click->ui--dialog#open" ].compact.join(" ")
    )

    user_aria = (opts.delete(:aria) || {}).dup
    opts[:aria] = user_aria.merge(
      haspopup: "dialog",
      expanded: "false",
      controls: @dialog.id
    )

    opts
  end

  private

  def merged_data
    user_data = (@html_attrs[:data] || {}).deep_dup
    user_action = user_data.delete(:action) || user_data.delete("action")
    user_data.merge(
      "ui--dialog-target": "trigger",
      action: [ user_action, "click->ui--dialog#open" ].compact.join(" ")
    )
  end

  def merged_aria
    (@html_attrs[:aria] || {}).deep_dup.merge(
      haspopup: "dialog",
      expanded: "false",
      controls: @dialog.id
    )
  end
end
