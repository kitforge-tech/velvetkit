# frozen_string_literal: true

# UI::ThemeToggle — System / Light / Dark picker.
#
# The preference lives in localStorage under `ui-theme` and is applied by the
# `ui--theme` Stimulus controller, which sets `.dark` on <html>. The initial
# class is set pre-paint by layouts/_theme_script to avoid a flash.
#
# Usage:
#   <%= render(UI::ThemeToggle.new) %>
class UI::ThemeToggle < UI::Base
  OPTIONS = [
    { value: "light",  key: "light",  icon: "sun" },
    { value: "dark",   key: "dark",   icon: "moon" },
    { value: "system", key: "system", icon: "monitor" }
  ].freeze

  def initialize(label: nil, class: nil, **html_attrs)
    @label      = label
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def wrapper_options
    opts = @html_attrs.dup
    opts[:data] = { controller: "ui--theme" }.merge(opts[:data] || {})
    opts[:class] = cn("contents", @user_class)
    opts
  end

  def trigger_options
    {
      variant: :ghost,
      size: :icon_sm,
      class: "size-7!",
      aria: { label: @label || I18n.t("ui.theme_toggle.label", default: "Change theme") }
    }
  end

  # Both icons are rendered and swapped with `dark:` variants rather than by
  # changing `data-lucide` at runtime: lucide replaces each <i> with an <svg>
  # on first render, so the original element is gone and a later attribute
  # change would do nothing.
  # The trigger shows the preference (html[data-theme], set before paint by
  # the theme script): sun for light, which is the default, moon for dark,
  # and a monitor while following the system.
  def sun_classes = "block in-data-[theme=dark]:hidden in-data-[theme=system]:hidden"
  def moon_classes = "hidden in-data-[theme=dark]:block"
  def system_classes = "hidden in-data-[theme=system]:block"

  def option_options(option)
    {
      role: "menuitemradio",
      class: "group",
      data: {
        theme: option[:value],
        action: "ui--theme#select",
        "ui--theme-target" => "option"
      },
      aria: { checked: "false" }
    }
  end
end
