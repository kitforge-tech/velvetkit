module ReleasesHelper
  UPGRADE_NOTE = /\AUpgrading an app: /

  # A version's notes on the releases page. Every page's header links here,
  # so it doesn't read the changelog: a version with no section yet (RubyGems
  # can be ahead of main) just opens the top of the page.
  def release_notes_path(version) = doc_path("releases", anchor: ReleaseNotes.anchor(version))

  # The version badge in the header and footer, linking to its notes.
  def version_badge(**html)
    version = ReleasedVersion.current
    link_to release_notes_path(version), **html, aria: { label: "v#{version} release notes" },
            class: class_names("rounded-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring", html[:class]) do
      render(UI::Badge.new(variant: :outline, class: "hover:bg-accent")) { "v#{version}" }
    end
  end

  # A component a release added, as a chip: a link while the kit still has
  # it, plain once it's gone, since a changelog keeps names a later version
  # may drop.
  def release_component_chip(class_name)
    name = class_name.underscore
    badge = render(UI::Badge.new(variant: :outline, class: ("hover:bg-accent" if component?(name)))) { name.humanize }
    return badge unless component?(name)

    link_to badge, component_path(name), class: "rounded-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
  end

  # "Upgrading an app: re-run …" as a heading and its text.
  def release_note_parts(note)
    note.match?(UPGRADE_NOTE) ? [ "Upgrading an app", note.sub(UPGRADE_NOTE, "").upcase_first ] : [ nil, note ]
  end

  # A changelog line as HTML: `code` spans become <code>, and a component's
  # class name (`MoneyInput`) links to its page.
  def release_text(text)
    parts = text.split(/`([^`]+)`/)
    safe_join(parts.each_with_index.map do |part, index|
      next part if index.even?

      code = tag.code(part, class: "font-mono text-sm")
      name = part.underscore
      part.match?(/\A[A-Z]\w*\z/) && component?(name) ? link_to(code, component_path(name), class: "text-primary underline-offset-4 hover:underline") : code
    end)
  end

  private

  def component?(name) = ComponentDoc.names.include?(name)
end
