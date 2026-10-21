# frozen_string_literal: true

class UI::Dialog::Close < UI::Base
  def initialize(variant: :ghost, size: :icon_sm, class: nil, **html_attrs)
    @variant = variant
    @size = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def set_content_context(content_context)
    @content_context = content_context
  end

  def button_class
    if content.present?
      cn(@user_class)
    else
      cn("absolute right-4 top-4 p-0", @user_class)
    end
  end

  def button_options
    opts = @html_attrs.deep_dup
    opts[:variant] = @variant
    opts[:size] = effective_size
    opts[:type] = :button
    opts[:class] = button_class
    opts[:data] = merged_data
    opts[:aria] = merged_aria
    opts
  end

  private

  def merged_data
    user_data = (@html_attrs[:data] || {}).deep_dup
    action = [ user_data.delete(:action) || user_data.delete("action"), "click->ui--dialog#close" ].compact.join(" ")

    user_data.merge(
      action: action,
      ui_dialog_close: true
    )
  end

  def merged_aria
    (@html_attrs[:aria] || {}).deep_dup.reverse_merge(label: I18n.t("ui.dialog.close_label", default: "Close"))
  end

  def effective_size
    content.present? && [ :icon, :icon_sm ].include?(@size) ? :default : @size
  end
end
