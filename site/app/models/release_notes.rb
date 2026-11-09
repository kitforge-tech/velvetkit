# The releases page, read from the gem's CHANGELOG.md so there's one copy of
# the notes. Each `## 0.4.1 — 2026-11-09` section is a release; under it,
# "New components:" and "Changes:" label the bullet lists, a bullet starting
# "Fix:" is a fix wherever it sits, and a paragraph (like "Upgrading an
# app: …") is a note. Unreleased isn't shown: it isn't out yet.
class ReleaseNotes
  FILE = Rails.root.join("../CHANGELOG.md")
  HEADING = /\A## (?<version>\S+) — (?<date>\d{4}-\d{2}-\d{2})\s*\z/

  # A release's id on the page, worked out from the version alone so a link to
  # it (the header's version badge) needn't read the changelog.
  def self.anchor(version) = "v#{version.tr(".", "-")}"

  Release = Data.define(:version, :date, :components, :changes, :fixes, :notes) do
    def id = ReleaseNotes.anchor(version)

    # The components a release added, by class name (`MoneyInput`).
    def component_names = components.flat_map { _1.scan(/`([A-Z]\w*)`/).flatten }.uniq

    # The lines that say what a component is (`` `Slider`: a handle … ``), not
    # a bare list of names, which the page already shows as links.
    def descriptions = components.grep(/\A`[A-Z]\w*`:/)
  end

  def self.all
    @all = nil if Rails.env.development?
    @all ||= parse(FILE.read).freeze
  end

  def self.parse(text)
    text.split(/^(?=## )/).filter_map { |section| release(section) }
  end

  def self.release(section)
    heading, *lines = section.lines
    match = HEADING.match(heading.strip) or return

    lists = { components: [], changes: [], fixes: [], notes: [] }
    group = :changes
    blocks(lines).each do |block|
      case block
      when "New components:" then group = :components
      when "Changes:" then group = :changes
      when /\A- Fix: (.*)/m then lists[:fixes] << Regexp.last_match(1).sub(/\A[a-z]/, &:upcase)
      when /\A- (.*)/m then lists[group] << Regexp.last_match(1)
      else lists[:notes] << block
      end
    end

    Release.new(version: match[:version], date: Date.iso8601(match[:date]), **lists)
  end

  # Bullets and paragraphs, each with its wrapped lines joined.
  def self.blocks(lines)
    lines.chunk_while { |_, line| line.start_with?("  ") || (line.strip.present? && !line.start_with?("- ")) }
         .map { |chunk| chunk.map(&:strip).join(" ").strip }
         .reject(&:empty?)
  end

  private_class_method :release, :blocks
end
