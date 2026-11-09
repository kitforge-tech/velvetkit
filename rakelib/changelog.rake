# frozen_string_literal: true

require "date"

# Cuts a release in CHANGELOG.md: what's under "## Unreleased" becomes
# "## 0.5.0 — 2026-11-20", below a new, empty Unreleased. It's the
# docs(changelog) PR that's merged before the tag is pushed (AGENTS.md).
module ChangelogRelease
  UNRELEASED = "## Unreleased"
  LASTMOD = %r{^"/docs/releases": '\d{4}-\d{2}-\d{2}'$}

  def self.cut(changelog, version, date)
    unless Gem::Version.correct?(version) && Gem::Version.new(version).to_s == version
      raise ArgumentError, "#{version.inspect} isn't a gem version, like 0.5.0 or 0.5.0.beta"
    end
    raise ArgumentError, "CHANGELOG.md has no #{UNRELEASED} section" unless changelog.match?(/^#{UNRELEASED}$/)
    raise ArgumentError, "#{version} is already in CHANGELOG.md" if changelog.match?(/^## #{Regexp.escape(version)} — /)

    latest = changelog[/^## (\S+) — /, 1]
    if latest && Gem::Version.new(version) <= Gem::Version.new(latest)
      raise ArgumentError, "#{version} isn't newer than #{latest}, the latest release"
    end

    unreleased = changelog[/^#{UNRELEASED}$(.*?)(?=^## |\z)/m, 1]
    raise ArgumentError, "Nothing under #{UNRELEASED} to release" if unreleased.strip.empty?

    changelog.sub(/^#{UNRELEASED}$/, "#{UNRELEASED}\n\n## #{version} — #{date.iso8601}")
  end

  # The releases page's sitemap date: the day the notes change, which is what
  # `bin/rails seo:lastmod` writes once the release is committed.
  def self.touch_lastmod(lastmod, date)
    raise ArgumentError, "site/config/lastmod.yml has no /docs/releases date" unless lastmod.match?(LASTMOD)

    lastmod.sub(LASTMOD, %("/docs/releases": '#{date.iso8601}'))
  end
end

namespace :changelog do
  desc "Cut a release in CHANGELOG.md from what's under Unreleased: rake changelog:release[0.5.0]"
  task :release, [ :version ] do |_, args|
    version = args[:version] or abort "Usage: rake changelog:release[0.5.0]"
    date = Date.today
    changelog = File.expand_path("../CHANGELOG.md", __dir__)
    lastmod = File.expand_path("../site/config/lastmod.yml", __dir__)

    begin
      File.write(changelog, ChangelogRelease.cut(File.read(changelog), version, date))
      File.write(lastmod, ChangelogRelease.touch_lastmod(File.read(lastmod), date))
    rescue ArgumentError => e
      abort e.message
    end

    puts <<~NEXT
      CHANGELOG.md: what was under Unreleased is now ## #{version} — #{date.iso8601}. Next:
        1. Read it over, then commit both files as docs(changelog): #{version} and open a PR.
        2. Once it's merged, push the tag: git fetch origin && git tag v#{version} origin/main && git push origin v#{version}
    NEXT
  end
end
