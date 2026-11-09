# frozen_string_literal: true

require "date"
require "open3"
require "yaml"

# Cuts a release in CHANGELOG.md, writing its notes from git so nobody has to:
# the components added since the last tag, each with its description from
# registry/components.yml, then a line for every merged PR that changed what
# an app gets from the kit, in the PR's own title. Anything written under
# "## Unreleased" by hand, like an "Upgrading an app:" note, is kept. The
# result is the docs(changelog) PR merged before the tag is pushed (AGENTS.md).
module ChangelogRelease
  UNRELEASED = "## Unreleased"
  LASTMOD = %r{^"/docs/releases": '\d{4}-\d{2}-\d{2}'$}
  # The files an app gets from the kit. A PR touching none of them (the docs
  # site, CI, this changelog) isn't a release note.
  KIT = %r{\A(registry/(app|config)/|registry/icons|lib/)}
  # Branch prefixes that are never a release note, whatever they touch.
  QUIET = %w[docs chore ci test style].freeze
  WIDTH = 78

  Pr = Data.define(:number, :branch, :title, :files) do
    def type = branch[%r{\A([a-z]+)/}, 1]
    def fix? = type == "fix"
    def kit? = !QUIET.include?(type) && files.any? { _1.match?(KIT) && _1 != "lib/velvetkit/version.rb" }

    # The components whose files it changes.
    def components
      files.filter_map { _1[%r{\Aregistry/app/(?:components|javascript/controllers)/ui/([a-z][a-z_]*?)(?:_controller)?[./]}, 1] }.uniq
    end
  end

  class << self
    # The new release's notes, as the Markdown under its heading.
    # components: the catalog now, { "rating" => { "description" => "…" } }
    # previous: the component names at the last release
    def notes(components:, previous:, prs:, unreleased:)
      added = components.keys - previous - [ "base" ]
      written = sort(unreleased)
      kit = prs.select(&:kit?).reject { unreleased.include?("(##{_1.number})") }
               .reject { (touched = _1.components & components.keys).any? && (touched - added).empty? }

      new_lines = added.reject { unreleased.include?("`#{class_name(_1)}`") }
                       .map { bullet("`#{class_name(_1)}`: #{lowercase_first(components.dig(_1, "description").to_s)}") }
      changes = kit.reject(&:fix?).map { bullet(pr_line(_1, components)) }
      fixes = kit.select(&:fix?).map { bullet("Fix: #{pr_line(_1, components)}") }

      [ list("New components:", new_lines + written[:components]),
        list("Changes:", changes + written[:changes] + fixes + written[:fixes]),
        *written[:notes] ].compact.join("\n\n")
    end

    def cut(changelog, version, date, notes)
      unless Gem::Version.correct?(version) && Gem::Version.new(version).to_s == version
        raise ArgumentError, "#{version.inspect} isn't a gem version, like 0.5.0 or 0.5.0.beta"
      end
      raise ArgumentError, "CHANGELOG.md has no #{UNRELEASED} section" unless changelog.match?(/^#{UNRELEASED}$/)
      raise ArgumentError, "#{version} is already in CHANGELOG.md" if changelog.match?(/^## #{Regexp.escape(version)} — /)

      latest = changelog[/^## (\S+) — /, 1]
      if latest && Gem::Version.new(version) <= Gem::Version.new(latest)
        raise ArgumentError, "#{version} isn't newer than #{latest}, the latest release"
      end
      raise ArgumentError, "Nothing to release: no new components, no PRs that changed the kit, and nothing under #{UNRELEASED}" if notes.strip.empty?

      changelog.sub(/^#{UNRELEASED}$.*?(?=^## |\z)/m) { "#{UNRELEASED}\n\n## #{version} — #{date.iso8601}\n\n#{notes.strip}\n\n" }
    end

    # The releases page's sitemap date: the day the notes change, which is what
    # `bin/rails seo:lastmod` writes once the release is committed.
    def touch_lastmod(lastmod, date)
      raise ArgumentError, "site/config/lastmod.yml has no /docs/releases date" unless lastmod.match?(LASTMOD)

      lastmod.sub(LASTMOD, %("/docs/releases": '#{date.iso8601}'))
    end

    # The PRs merged into `to` since `from`, read from GitHub's merge commits
    # ("Merge pull request #80 from owner/fix/branch", the PR title below).
    def prs(root, from:, to: "HEAD")
      log = git(root, "log", "--first-parent", "--merges", "--format=%H%x1f%s%x1f%b%x1e", "#{from}..#{to}")
      log.split("\x1e").filter_map do |entry|
        sha, subject, body = entry.strip.split("\x1f")
        match = subject.to_s.match(%r{\AMerge pull request #(\d+) from [^/]+/(.+)\z}) or next
        title = body.to_s.strip.lines.first&.strip || match[2]
        Pr.new(number: match[1].to_i, branch: match[2], title: title, files: git(root, "diff", "--name-only", "#{sha}^1", sha).split("\n"))
      end.reverse
    end

    # Commits put on `to` directly, not through a PR, which `prs` can't see.
    def direct_commits(root, from:, to: "HEAD")
      git(root, "log", "--first-parent", "--no-merges", "--format=%h %s", "#{from}..#{to}").split("\n")
    end

    def last_tag(root) = git(root, "describe", "--tags", "--abbrev=0", "--match", "v*").strip

    def catalog(yaml) = YAML.safe_load(yaml).fetch("components")

    def git(root, *args)
      out, err, status = Open3.capture3("git", "-C", root, *args)
      raise ArgumentError, "git #{args.first} failed: #{err.strip}" unless status.success?

      out
    end

    private

    def class_name(name) = name.split("_").map(&:capitalize).join

    # "A pulsing placeholder" reads on after "`Skeleton`: "; "QR codes" keeps its capitals.
    def lowercase_first(text) = text.match?(/\A[A-Z](?:[a-z]|\s)/) ? text[0].downcase + text[1..] : text

    # A PR's title as a line, its component in backticks so the releases page
    # links it: "Date Picker: ranges", "InputGroup: a border" and
    # "fix(input_group): a border" all lead with the component.
    def pr_line(pr, components)
      title = pr.title.strip
      if (conventional = title.match(/\A[a-z]+(?:\(([^)]+)\))?!?: (.+)\z/))
        lead, rest = conventional[1], conventional[2]
        title = rest[0].upcase + rest[1..]
      else
        lead, rest = title.split(": ", 2)
      end
      name = lead.to_s.strip.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.tr(" -", "__")
      text = rest && components.key?(name) ? "`#{class_name(name)}`: #{rest}" : title
      "#{text} (##{pr.number})"
    end

    def list(label, bullets) = ("#{label}\n\n#{bullets.join("\n")}" if bullets.any?)

    # A bullet wrapped like the rest of the changelog.
    def bullet(text)
      text.split.each_with_object([ +"-" ]) do |word, lines|
        lines.last.length + word.length + 1 > WIDTH ? lines << "  #{word}" : lines.last << " #{word}"
      end.join("\n")
    end

    # What was written under Unreleased by hand, sorted the way the releases
    # page reads it: bullets under "New components:" or "Changes:" (a "Fix:"
    # one last), and paragraphs as notes.
    def sort(text)
      written = { components: [], changes: [], fixes: [], notes: [] }
      group = :changes
      text.split(/\n\s*\n/).flat_map { _1.split(/\n(?=- )/) }.map(&:strip).reject(&:empty?).each do |block|
        case block
        when "New components:" then group = :components
        when "Changes:" then group = :changes
        when /\A- Fix: / then written[:fixes] << block
        when /\A- / then written[group] << block
        else written[:notes] << block
        end
      end
      written
    end
  end
end

namespace :changelog do
  desc "Write the next release into CHANGELOG.md from git: rake changelog:release[0.5.0]"
  task :release, [ :version ] do |_, args|
    version = args[:version] or abort "Usage: rake changelog:release[0.5.0]"
    root = File.expand_path("..", __dir__)
    changelog = File.join(root, "CHANGELOG.md")
    lastmod = File.join(root, "site/config/lastmod.yml")
    date = Date.today

    begin
      tag = ChangelogRelease.last_tag(root)
      text = File.read(changelog)
      unreleased = text[/^#{ChangelogRelease::UNRELEASED}$(.*?)(?=^## |\z)/m, 1].to_s
      prs = ChangelogRelease.prs(root, from: tag)
      notes = ChangelogRelease.notes(components: ChangelogRelease.catalog(File.read(File.join(root, "registry/components.yml"))),
                                     previous: ChangelogRelease.catalog(ChangelogRelease.git(root, "show", "#{tag}:registry/components.yml")).keys,
                                     prs: prs, unreleased: unreleased)
      File.write(changelog, ChangelogRelease.cut(text, version, date, notes))
      File.write(lastmod, ChangelogRelease.touch_lastmod(File.read(lastmod), date))
    rescue ArgumentError => e
      abort e.message
    end

    skipped = prs.reject(&:kit?)
    direct = ChangelogRelease.direct_commits(root, from: tag)
    puts <<~DONE
      CHANGELOG.md: ## #{version} — #{date.iso8601}, written from #{tag}..HEAD (#{prs.size} PRs).
      #{"Left out, as they don't change the kit: #{skipped.map { "##{_1.number}" }.join(", ")}\n" if skipped.any?}#{"Not from a PR, so not listed (run it on a branch from an up-to-date origin/main): #{direct.join("; ")}\n" if direct.any?}
      Next:
        1. Read the section over and edit any line that reads badly; add an "Upgrading an app:" note if one's needed.
        2. Commit CHANGELOG.md and site/config/lastmod.yml as docs(changelog): #{version}, and open a PR.
        3. Once it's merged, push the tag: git fetch origin && git tag v#{version} origin/main && git push origin v#{version}
    DONE
  end
end
