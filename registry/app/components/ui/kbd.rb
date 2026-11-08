# frozen_string_literal: true

# A keyboard key, or a shortcut, written the way the reader's computer labels
# it. "mod" is ⌘ on a Mac and Ctrl elsewhere:
#
#   <%= render(UI::Kbd.new("mod+k")) %>            ⌘K, or Ctrl+K
#   <%= render(UI::Kbd.new("shift+enter")) %>      ⇧↵, or Shift+Enter
#   <%= render(UI::Kbd.new(%w[g i])) %>            G then I
#   <%= render(UI::Kbd.new) { "Fn" } %>            any key, as written
#
# It takes its colours from the text around it, so it reads the same in a
# paragraph, a menu, a tooltip or a filled button.
#
# Names: mod, cmd (meta), ctrl, alt (option), shift, enter, esc, tab, space,
# backspace, delete, up, down, left, right; anything else (k, /, F5) is shown
# as written, a single letter in capitals. Screen readers hear the key's name,
# "Command", not the symbol.
#
# The Mac or not guess comes from the browser's user agent, so the page
# doesn't change once it's loaded; the controller corrects it if a cached
# page guessed for someone else.
#
# `bind: true` makes the shortcut press the button or link it sits in (a
# sequence can't be bound); `bind: "#save"` presses that element instead, or
# focuses it if it's a field, like "/" for search. It
# leaves typing alone, unless the shortcut uses mod, ctrl or alt, and the
# element gets aria-keyshortcuts so screen readers announce it.
class UI::Kbd < UI::Base
  # name => [Mac symbol, Mac name, other label, other name]
  KEYS = {
    "mod"       => [ "⌘", "Command", "Ctrl", "Control" ],
    "cmd"       => [ "⌘", "Command", "Win", "Windows" ],
    "ctrl"      => [ "⌃", "Control", "Ctrl", "Control" ],
    "alt"       => [ "⌥", "Option", "Alt", "Alt" ],
    "shift"     => [ "⇧", "Shift", "Shift", "Shift" ],
    "enter"     => [ "↵", "Return", "Enter", "Enter" ],
    "esc"       => [ "Esc", "Escape", "Esc", "Escape" ],
    "tab"       => [ "⇥", "Tab", "Tab", "Tab" ],
    "space"     => [ "Space", "Space", "Space", "Space" ],
    "backspace" => [ "⌫", "Delete", "Backspace", "Backspace" ],
    "delete"    => [ "⌦", "Forward Delete", "Del", "Delete" ],
    "up"        => [ "↑", "Up Arrow", "↑", "Up Arrow" ],
    "down"      => [ "↓", "Down Arrow", "↓", "Down Arrow" ],
    "left"      => [ "←", "Left Arrow", "←", "Left Arrow" ],
    "right"     => [ "→", "Right Arrow", "→", "Right Arrow" ]
  }.freeze

  ALIASES = { "command" => "cmd", "meta" => "cmd", "control" => "ctrl", "option" => "alt", "opt" => "alt",
              "return" => "enter", "escape" => "esc", "del" => "delete", "arrowup" => "up",
              "arrowdown" => "down", "arrowleft" => "left", "arrowright" => "right" }.freeze

  SIZES = {
    sm:      "h-4 min-w-4 px-1 text-[10px]",
    default: "h-5 min-w-5 px-1 text-xs",
    lg:      "h-6 min-w-6 px-1.5 text-sm"
  }.freeze

  KEY = "inline-flex items-center justify-center rounded-sm border border-current/15 bg-current/[0.07] " \
        "font-sans font-medium leading-none tracking-normal whitespace-nowrap shadow-[0_1px_0] shadow-current/10"

  APPLE = /Macintosh|Mac OS X|iPhone|iPad|iPod/

  def initialize(keys = nil, size: :default, bind: nil, class: nil, **html_attrs)
    @keys       = keys
    @size       = SIZES.key?(size.to_sym) ? size.to_sym : :default
    @bind       = bind
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  # One combo per step: "mod+k" is one step, %w[g i] two.
  def steps
    Array(@keys).map { |combo| combo.to_s.split("+").map(&:strip).reject(&:empty?) }.reject(&:empty?)
  end

  def written? = @keys.nil?

  def platform = apple? ? "mac" : "other"

  # [mac label, mac name, other label, other name] for one key.
  def key_labels(key)
    name = ALIASES.fetch(key.downcase, key.downcase)
    return KEYS[name] if KEYS.key?(name)

    label = key.length == 1 ? key.upcase : key
    [ label, label, label, label ]
  end

  def key_class = cn(KEY, SIZES[@size])

  # One key: the symbol shown, its name for screen readers. A key that's
  # already a word (Esc, F5) is just the word.
  def key_tag(label, name, extra = nil)
    face = label == name ? label : safe_join([ tag.span(label, aria: { hidden: true }), tag.span(name, class: "sr-only") ])
    tag.kbd(face, class: cn(key_class, extra))
  end

  def root_attrs
    { **@html_attrs, class: cn("group/kbd inline-flex items-center gap-1 align-middle font-sans font-normal text-current/80", @user_class),
      data: { slot: "kbd", platform: platform, controller: "ui--kbd", **bind_data, **(@html_attrs[:data] || {}) } }
  end

  private

  def bind_data
    return {} unless @bind && steps.size == 1

    { "ui--kbd-keys-value": steps.first.join("+"), "ui--kbd-target-value": (@bind == true ? "" : @bind.to_s) }
  end

  def apple?
    request&.user_agent.to_s.match?(APPLE)
  rescue StandardError
    false
  end
end
