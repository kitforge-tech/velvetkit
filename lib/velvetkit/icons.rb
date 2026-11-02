# frozen_string_literal: true

require "yaml"
require "net/http"

module Velvetkit
  # The icon libraries an app can choose, and how the kit's icons get there.
  #
  # Like shadcn/ui, the choice is made when components are copied, not at
  # runtime. The registry is written with Lucide names; on the way into an
  # app whose config/velvetkit.yml says `icons: phosphor`, every icon name
  # in a component, its test and its preview is swapped for Phosphor's
  # (`circle-alert` → `warning-circle`), and the SVGs it draws are copied to
  # app/assets/icons. After that the app's code names its own library's
  # icons and nothing looks anything up.
  #
  # registry/icons.yml lists every icon the kit and its previews draw, by its
  # Lucide name, with its name in each other library. registry/icons/<library>/
  # holds the SVGs, fetched by `rake icons:sync`.
  class Icons
    CANONICAL = "lucide"

    # Where each library's SVGs are published, one file per icon.
    LIBRARIES = {
      "lucide" => { package: "lucide-static", version: "0.545.0", file: "icons/%s.svg",
                    license: "ISC", browse: "https://lucide.dev/icons" },
      "tabler" => { package: "@tabler/icons", version: "3.50.0", file: "icons/outline/%s.svg",
                    license: "MIT", browse: "https://tabler.io/icons" },
      "phosphor" => { package: "@phosphor-icons/core", version: "2.1.1", file: "assets/regular/%s.svg",
                      license: "MIT", browse: "https://phosphoricons.com" }
    }.freeze

    NAME = /[a-z0-9]+(?:-[a-z0-9]+)*/

    # Each way the kit's source names an icon, in a `name` group (`symbol`
    # for `name: :x`). Only that group is renamed.
    #
    #   UI::Icon.new(name: "check")   with_leading_icon(name: :x)
    #   dismiss_icon: "x"             { icon: "sun" }
    #   svg[data-icon='x']            (tests)
    PATTERNS = [
      /(?:Icon\.new|_icon)\(\s*name:\s*"(?<name>#{NAME})"/,
      /(?:Icon\.new|_icon)\(\s*name:\s*:(?<symbol>[a-z0-9_]+)\b/,
      /\b(?:\w+_)?icon:\s*"(?<name>#{NAME})"/,
      /data-icon=\\?['"](?<name>#{NAME})/
    ].freeze

    #   DEFAULT_ICONS = { default: "info", destructive: "circle-alert" }
    MAP = /ICONS\s*=\s*\{(?<body>.*?)\}/m

    def self.library!(name)
      name = (name || CANONICAL).to_s
      return name if LIBRARIES.key?(name)

      raise Error, "Unknown icon library #{name.inspect}. Available: #{LIBRARIES.keys.join(', ')}"
    end

    attr_reader :root

    def initialize(root)
      @root = root
      @names = YAML.load_file(File.join(root, "icons.yml"))
    end

    # Every icon the registry knows, by its Lucide name.
    def canonical
      @names.keys
    end

    # An icon's name in `library`, or nil if the registry doesn't map it.
    def name(icon, library)
      return (@names.key?(icon) ? icon : nil) if library == CANONICAL

      @names.dig(icon, library)
    end

    # The Lucide names the source draws. Comments don't count.
    def names_in(source)
      code = without_comments(source)
      names = PATTERNS.flat_map { |pattern| code.to_enum(:scan, pattern).map { icon_in(Regexp.last_match) } }
      code.scan(MAP).flatten.each { |body| names += body.scan(/"(#{NAME})"/o).flatten }
      names.uniq
    end

    # The source with every icon the registry maps renamed for `library`.
    # Names it doesn't map are left alone.
    def rewrite(source, library)
      return source if library == CANONICAL

      rename = ->(icon) { name(icon, library) || icon }
      source = PATTERNS.reduce(source) do |text, pattern|
        text.gsub(pattern) do |match|
          found = Regexp.last_match
          icon = icon_in(found)
          next match if rename.call(icon) == icon

          group = found.names.first
          from = found.begin(group) - found.begin(0)
          to = found.end(group) - found.begin(0)
          # A symbol (`name: :x`) becomes a string: most names have a dash.
          from -= 1 if group == "symbol"
          match[0...from] + (group == "symbol" ? %("#{rename.call(icon)}") : rename.call(icon)) + match[to..]
        end
      end
      source.gsub(MAP) { |map| map.gsub(/"(#{NAME})"/o) { %("#{rename.call(Regexp.last_match(1))}") } }
    end

    # The registry's copy of an icon's SVG, by its Lucide name.
    def svg_file(icon, library)
      File.join("icons", library, "#{name(icon, library)}.svg")
    end

    # An icon's SVG, by its name in `library`, from the npm CDN. Tagged with
    # its license, which the ISC and MIT licenses ask copies to keep.
    def self.download(icon, library)
      raise Error, "#{icon.inspect} isn't an icon name" unless icon.match?(/\A#{NAME}\z/o)

      spec = LIBRARIES.fetch(library)
      uri = URI("https://unpkg.com/#{spec[:package]}@#{spec[:version]}/#{format(spec[:file], icon)}")
      response = fetch(uri)
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "#{library} has no icon named #{icon.inspect} (#{uri} answered #{response.code}). " \
                     "Browse them at #{spec[:browse]}"
      end

      svg = response.body.sub(/\A\s*<!--.*?-->\s*/m, "").strip
      "<!-- @license #{spec[:package]} v#{spec[:version]} - #{spec[:license]} -->\n#{svg}\n"
    end

    def self.fetch(uri, redirects = 3)
      response = Net::HTTP.get_response(uri)
      return response unless response.is_a?(Net::HTTPRedirection) && redirects.positive?

      fetch(URI.join(uri, response["location"]), redirects - 1)
    end
    private_class_method :fetch

    private

    def icon_in(match)
      match.names.include?("symbol") ? match[:symbol].tr("_", "-") : match[:name]
    end

    def without_comments(source)
      source.gsub(/<%#.*?%>/m, "").lines.grep_v(/\A\s*#/).join
    end
  end
end
