# frozen_string_literal: true

require "securerandom"

# One thing to pick in a UI::Command: a page to go to (`href:`) or an action
# (`value:`, handled from `ui--command:select`). `keywords:` are other words
# it's found by. A block replaces how it looks; the label still finds it.
#
# `shortcut:` shows the item's shortcut, with UI::Kbd; with `bind: true` the
# shortcut also picks it from anywhere on the page, palette open or not.
class UI::Command::Item < UI::Base
  BASE = "relative flex cursor-default select-none items-center gap-3 rounded-md px-2 py-2 text-sm outline-none " \
         "data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground " \
         "aria-disabled:pointer-events-none aria-disabled:opacity-50"

  def initialize(label:, href: nil, value: nil, icon: nil, description: nil, keywords: nil, shortcut: nil, bind: false,
                 disabled: false, class: nil, **html_attrs)
    @label       = label
    @href        = href
    @value       = value || href || label
    @icon        = icon
    @description = description
    @keywords    = Array(keywords).join(" ")
    @shortcut    = shortcut
    @bind        = bind
    @disabled    = disabled
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
    @id          = html_attrs[:id] || "ui-command-item-#{SecureRandom.hex(4)}"
  end

  def call
    tag.div(**@html_attrs, id: @id, role: "option", class: cn(BASE, @user_class),
            aria: { disabled: (true if @disabled), selected: "false" }.compact,
            data: { "ui--command-target": "item", value: @value, href: @href, label: @label,
                    keywords: (@keywords if @keywords.present?), **(@html_attrs[:data] || {}) }.compact) do
      safe_join([ icon, body, shortcut ].compact)
    end
  end

  private

  def icon
    return unless @icon

    tag.span(render(UI::Icon.new(name: @icon, size: :sm)), class: "flex shrink-0 text-muted-foreground", aria: { hidden: true })
  end

  def body
    return tag.span(content, class: "min-w-0 flex-1") if content?

    tag.span(class: "flex min-w-0 flex-1 flex-col") do
      safe_join([ tag.span(@label, class: "truncate"),
                 (tag.span(@description, class: "truncate text-xs text-muted-foreground") if @description) ].compact)
    end
  end

  def shortcut
    return unless @shortcut

    render(UI::Kbd.new(@shortcut, size: :sm, class: "ms-auto text-muted-foreground",
                                  bind: (@bind && !@disabled ? "##{@id}" : nil)))
  end
end
