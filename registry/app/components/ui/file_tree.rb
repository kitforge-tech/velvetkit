# frozen_string_literal: true

# Folders and files as a tree: a repository's source, a project's documents,
# the pages of a site. Folders open and close, and a file is a link or, with
# no `href:`, a row to pick.
#
#   <%= render(UI::FileTree.new(label: "Project files")) do |tree| %>
#     <% tree.with_folder(name: "app") do |app| %>
#       <% app.with_folder(name: "models") do |models| %>
#         <% models.with_file(name: "user.rb", href: blob_path("app/models/user.rb"), active: true) %>
#       <% end %>
#     <% end %>
#     <% tree.with_file(name: "README.md", href: blob_path("README.md")) %>
#   <% end %>
#
# Or from data, where a hash with `children:` is a folder and any other a
# file, taking the same options as UI::FileTree::Folder and
# UI::FileTree::FileItem:
#
#   <%= render(UI::FileTree.new(items: [
#     { name: "app", children: [ { name: "user.rb", value: "app/user.rb" } ] },
#     { name: "README.md", value: "README.md" }
#   ])) %>
#
# A folder holding the `active:` file starts open; `open:` decides it
# otherwise. Rows follow the WAI-ARIA tree pattern: one is in the tab order,
# Up and Down move between them, Right opens a folder and Left closes it or
# goes to its parent, and typing a letter jumps to the next name starting with
# it. Picking a file with no `href:` selects it and dispatches
# `ui--file-tree:select` with `{ value, name }`.
#
# A folder slides open and shut on the easing iOS uses for its sheets, and
# reverses smoothly if clicked again part way; with reduced motion asked for,
# it opens at once.
#
# `guides: false` drops the line down the side of each open folder.
class UI::FileTree < UI::Base
  # Every row, folder or file. A treeitem is the row itself, so the focus ring
  # and the selection are drawn on the row and not round a whole folder.
  # --primary is too dark to read as text on the dark surface, so in dark the
  # selected row keeps its tint and icon but not its text colour.
  ROW = "group/row flex h-7 w-full min-w-0 cursor-pointer select-none items-center gap-1.5 rounded-md px-2 " \
        "text-sm text-foreground hover:bg-accent hover:text-accent-foreground " \
        "aria-selected:bg-primary/10 aria-selected:font-medium aria-selected:text-primary " \
        "aria-selected:hover:bg-primary/15 aria-selected:hover:text-primary " \
        "dark:aria-selected:bg-primary/20 dark:aria-selected:text-foreground " \
        "dark:aria-selected:hover:bg-primary/25 dark:aria-selected:hover:text-foreground " \
        "#{UI::Base::FOCUS_RING}".freeze

  # Between rows, and between a folder and its first row. The focus ring
  # reaches 3px past its row (2px ring, 1px offset), so this leaves as much
  # again before the next row's hover.
  GAP = "gap-1.5"

  renders_many :items, types: {
    folder: { renders: UI::FileTree::Folder, as: :folder },
    file:   { renders: UI::FileTree::FileItem, as: :file }
  }

  # Adds a row to `branch` (the tree or a folder) for each hash in `entries`.
  def self.add_entries(branch, entries)
    Array(entries).each do |entry|
      entry = entry.to_h.symbolize_keys
      entry.key?(:children) ? branch.with_folder(**entry) : branch.with_file(**entry)
    end
  end

  def initialize(items: nil, label: nil, guides: true, class: nil, **html_attrs)
    @entries    = items
    @label      = label
    @guides     = guides
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def before_render
    UI::FileTree.add_entries(self, @entries)
    items.each_with_index { |item, index| item.place(level: 1, guides: @guides, tabbable: index.zero?) }
  end

  def root_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:role]  = "tree"
    attrs[:class] = cn("flex w-full flex-col #{GAP}", @user_class)
    attrs[:aria]  = { label: @label || t("ui.file_tree.label", default: "Files") }.merge(@html_attrs[:aria] || {})
    attrs[:data]  = {
      slot: "file-tree",
      controller: "ui--file-tree",
      action: "click->ui--file-tree#click keydown->ui--file-tree#keydown"
    }.merge(@html_attrs[:data] || {})
    attrs
  end
end
