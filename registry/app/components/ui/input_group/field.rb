# frozen_string_literal: true

# UI::InputGroup::Field — a UI::Input variant stripped of its own
# border/shadow/ring so the parent wrapper owns those styles.
#
# The wrapper owns the focus treatment via :focus-within; the field strips
# its own outline + ring so there is no double indicator on focus.
class UI::InputGroup::Field < UI::Input
  STRIPPED_CLASSES =
    "flex-1 w-full h-9 px-3 py-2 text-sm rounded-md text-foreground " \
    "placeholder:text-muted-foreground " \
    "border-0! bg-transparent shadow-none! " \
    "outline-none! focus:outline-none! focus:outline-none! focus:ring-0! " \
    "dark:bg-transparent " \
    "disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-muted/50"

  def initialize(**args)
    super(**args)
    @html_attrs[:data] ||= {}
    @html_attrs[:data][:slot] = "input-group-control"
  end

  def classes
    STRIPPED_CLASSES
  end
end
