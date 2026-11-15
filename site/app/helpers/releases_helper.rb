module ReleasesHelper
  UPGRADE_NOTE = /\AUpgrading an app: /
  # The velvet of the sidebar's current link, so the label reads as the
  # site's own in both themes.
  NEW_LABEL = "bg-primary/10 text-primary hover:bg-primary/10 dark:bg-primary/20 dark:text-[#c9a3f2] dark:hover:bg-primary/20"
  # Code in the notes: a tint and a size a little under the words around it,
  # so it reads as code without crowding them.
  CODE = "rounded bg-muted px-1 py-0.5 font-mono text-[0.875em]"

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

  # The release that added a component, while it's one the newest minor
  # version added; nil otherwise. Worked out once a request, as the sidebar
  # asks it of every component.
  def new_in(name) = (@new_components ||= ReleaseNotes.new_components)[name.to_s]

  # "New", beside a component's name.
  def new_label(text = "New", size: :sm, **html)
    render(UI::Badge.new(variant: :secondary, size: size, class: NEW_LABEL, **html)) { text }
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

  # A span of code. A short word stays on one line rather than breaking at a
  # hyphen (vanilla-calendar-pro); anything longer wraps, inside a word only
  # if it must, so a phone never scrolls sideways.
  def release_code(text)
    tag.code(text, class: [ CODE, text.match?(/\A\S{1,24}\z/) ? "whitespace-nowrap" : "break-words" ])
  end

  # A changelog line as HTML: `code` spans become <code>, a component's class
  # name (`MoneyInput`) links to its page, and "(#80)" to the pull request.
  def release_text(text)
    parts = text.split(/`([^`]+)`/)
    safe_join(parts.each_with_index.map do |part, index|
      next link_pull_requests(part) if index.even?

      code = release_code(part)
      name = part.underscore
      part.match?(/\A[A-Z]\w*\z/) && component?(name) ? link_to(code, component_path(name), class: "text-primary underline-offset-4 hover:underline") : code
    end)
  end

  private

  def component?(name) = ComponentDoc.names.include?(name)

  def link_pull_requests(text)
    safe_join(text.split(/\(#(\d+)\)/).each_with_index.map do |part, index|
      next part if index.even?

      safe_join([ "(", link_to("##{part}", "#{ApplicationHelper::GITHUB_URL}/pull/#{part}", class: "text-primary underline-offset-4 hover:underline"), ")" ])
    end)
  end
end
