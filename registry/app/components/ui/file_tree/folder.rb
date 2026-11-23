# frozen_string_literal: true

# A folder in a UI::FileTree: a row that opens and closes the folders and
# files added to it with `with_folder` and `with_file`, or listed in
# `children:` as hashes (see UI::FileTree).
#
# `open:` nil (the default) opens it when it holds the `active:` file, so the
# current file is in view; true or false decides. `icon:` swaps the folder
# icon for another.
class UI::FileTree::Folder < UI::Base
  # The guide is a line of its own and not a border, so that while the folder
  # has focus it can start lower down, past the ring, rather than run into it.
  # It sits inside the padding, where the overflow the animation clips to
  # can't cut it in half.
  GUIDE = "relative ms-[calc(1rem-0.5px)] ps-[calc(0.375rem+0.5px)] " \
          "before:absolute before:inset-y-0 before:start-0 before:w-px before:bg-border " \
          "before:transition-[top] peer-focus/row:before:top-1.5"

  renders_many :items, types: {
    folder: { renders: UI::FileTree::Folder, as: :folder },
    file:   { renders: UI::FileTree::FileItem, as: :file }
  }

  attr_reader :name, :icon

  def initialize(name:, open: nil, icon: "folder", children: nil, class: nil, **html_attrs)
    @name       = name
    @open       = open
    @icon       = icon
    @children   = children
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @level      = 1
    @guides     = true
    @tabbable   = false
  end

  # Set by the tree or folder holding this one, before it draws it.
  def place(level:, guides:, tabbable: false)
    @level    = level
    @guides   = guides
    @tabbable = tabbable
  end

  def before_render
    UI::FileTree.add_entries(self, @children)
    items.each { |item| item.place(level: @level + 1, guides: @guides) }
  end

  # Known once the items are drawn, since a folder inside finds out then.
  def active? = items.any?(&:active?)
  def open? = @open.nil? ? active? : @open

  def group_id
    @group_id ||= @html_attrs[:id] ? "#{@html_attrs[:id]}-group" : "ui-file-tree-group-#{SecureRandom.hex(4)}"
  end

  def row_attrs
    attrs = @html_attrs.except(:data, :aria, :id)
    attrs[:role]     = "treeitem"
    attrs[:tabindex] = @tabbable ? 0 : -1
    attrs[:class]    = cn(UI::FileTree::ROW, "peer/row", @user_class)
    attrs[:aria]     = { expanded: open?.to_s, level: @level, owns: group_id }.merge(@html_attrs[:aria] || {})
    attrs[:data]     = { slot: "file-tree-folder", name: @name, "ui--file-tree-target": "item" }
                         .merge(@html_attrs[:data] || {})
    attrs
  end

  # Indented so a folder's rows start under its icon, with the guide line
  # running down from the middle of its chevron. The space above the first
  # row is its margin, not the group's padding: padding would hold the group
  # open at that height until the closing animation ended, then let it drop.
  def group_classes
    cn("flex flex-col [&>li:first-child]:mt-1.5", UI::FileTree::GAP, @guides ? GUIDE : "ps-5.5")
  end
end
