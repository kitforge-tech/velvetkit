# frozen_string_literal: true

require "tailwind_merge"

module UI; end

class UI::Base < ViewComponent::Base
  # Shared focus ring, VelvetKit's signature: every interactive UI:: component
  # includes it in its variant `base:` string. It shows on click as well as on
  # Tab, and animates in. (The docs site keeps it on the clicked link across
  # page visits, so a visit doesn't cut the animation off.)
  FOCUS_RING = "transition-all focus:outline-none focus:ring-2 focus:ring-primary " \
               "focus:ring-offset-1 ring-offset-background"

  class_attribute :variant_config,
                  instance_writer: false,
                  default: { base: nil, variants: {}, defaults: {}, compound: [] }

  def cn(*classes)
    flattened = classes.flatten.compact.flat_map { |c|
      case c
      when String then c
      when Hash   then c.select { |_, v| v }.keys.map(&:to_s)
      else             nil
      end
    }.compact.reject(&:empty?).join(" ")

    UI::Base.tailwind_merger.merge(flattened)
  end

  def self.tailwind_merger
    @tailwind_merger ||= TailwindMerge::Merger.new
  end

  def self.variants(base:, variants: {}, defaults: {}, compound: [])
    self.variant_config = {
      base: base, variants: variants, defaults: defaults, compound: compound
    }
  end

  def variant_classes(**props)
    cfg = self.class.variant_config
    selected = cfg[:defaults].merge(props.compact)
    pieces = [ cfg[:base] ]
    cfg[:variants].each do |key, map|
      pieces << map[selected[key]]
    end
    cfg[:compound].each do |rule|
      pieces << rule[:class] if rule[:when].all? { |k, v| selected[k] == v }
    end
    cn(*pieces)
  end
end
