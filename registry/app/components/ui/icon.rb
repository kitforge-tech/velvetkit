# frozen_string_literal: true

# UI::Icon — an SVG icon, drawn into the page on the server.
#
# Each icon is a file in app/assets/icons, named as your icon library names
# it: `UI::Icon.new(name: "rocket")` draws app/assets/icons/rocket.svg. The
# library is the one in config/velvetkit.yml; `velvetkit:add` copies the
# icons the components draw, and this adds any other:
#
#   bin/rails generate velvetkit:icons rocket user
#
# There is no JavaScript and nothing to register. An icon with no file draws
# a dashed square (nothing in production) and logs which file is missing.
#
#   name:  the file's name, without .svg
#   size:  xs, sm, default, lg or xl
#   label: makes it an image with this accessible name; without one it is
#          decorative and hidden from assistive technology
#
# To keep the SVGs somewhere else, set `config.x.velvetkit.icons_path`.
class UI::Icon < UI::Base
  variants(
    base: "inline-block shrink-0",
    variants: {
      size: {
        xs:      "w-3 h-3",
        sm:      "w-4 h-4",
        default: "w-5 h-5",
        lg:      "w-6 h-6",
        xl:      "w-8 h-8"
      }
    },
    defaults: { size: :default }
  )

  # Shown in place of an icon with no file, outside production.
  MISSING = { viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "2",
              "stroke-dasharray": "3 3", inner: '<rect x="3" y="3" width="18" height="18" rx="2"/>' }.freeze

  class << self
    def path
      Rails.configuration.x.velvetkit.icons_path || Rails.root.join("app/assets/icons")
    end

    # The SVG's attributes and markup, or nil if there's no such file. The
    # library's own size and class are dropped: the component sets those.
    def svg(name)
      return unless name.match?(/\A[\w-]+\z/) # a file name, never a path

      cache = Rails.configuration.cache_classes ? (@svgs ||= {}) : {}
      cache.fetch(name) do
        file = File.join(path, "#{name}.svg")
        next unless File.file?(file)

        cache[name] = parse(File.read(file))
      end
    end

    private

    def parse(source)
      open_tag, inner = source.gsub(/<!--.*?-->/m, "").match(%r{<svg\b([^>]*)>(.*)</svg>}m)&.captures
      return unless open_tag

      attributes = open_tag.scan(/([\w:-]+)\s*=\s*"([^"]*)"/).to_h.except("width", "height", "class")
      { attributes: attributes.freeze, inner: inner.gsub(/>\s+</, "><").strip.freeze }.freeze
    end
  end

  def initialize(name:, size: :default, label: nil, class: nil, **html_attrs)
    @name = name.to_s
    @size = size
    @label = label
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :name

  def render?
    @name.present?
  end

  def svg_tag
    svg = self.class.svg(@name) || missing
    tag.svg(
      svg[:inner].html_safe, # the app's own SVG files
      **svg[:attributes].symbolize_keys,
      **@html_attrs.except(:data, :aria),
      class: cn(variant_classes(size: @size), @user_class),
      data: (@html_attrs[:data] || {}).merge(icon: @name),
      aria: aria_attributes,
      role: (accessible_name ? "img" : nil)
    )
  end

  private

  def accessible_name
    @label || @html_attrs.dig(:aria, :label)
  end

  def aria_attributes
    (accessible_name ? { label: accessible_name } : { hidden: true }).merge(@html_attrs[:aria] || {})
  end

  def missing
    Rails.logger&.warn("[UI::Icon] no #{@name}.svg in #{self.class.path}: bin/rails generate velvetkit:icons #{@name}")
    return { attributes: { "data-icon-missing" => "" }, inner: "" } if Rails.env.production?

    { attributes: MISSING.except(:inner).transform_keys(&:to_s).merge("data-icon-missing" => ""), inner: MISSING[:inner] }
  end
end
