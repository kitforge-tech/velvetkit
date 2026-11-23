# frozen_string_literal: true

# A file in a UI::FileTree, added with `with_file`. With `href:` it's a link,
# and `active: true` marks it as the page being shown (aria-current="page").
# Without one it's a row to pick: the tree selects it and dispatches
# `ui--file-tree:select` with its `value:` (its name if not given) and name.
# `active: true` starts it selected.
#
# The block is shown at the end of the row, for a little more about the file
# (a size, a "M" for modified).
class UI::FileTree::FileItem < UI::Base
  attr_reader :name, :icon

  def initialize(name:, href: nil, active: false, value: nil, icon: "file", class: nil, **html_attrs)
    @name       = name
    @href       = href
    @active     = active
    @value      = value || name
    @icon       = icon
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @level      = 1
    @guides     = true
    @tabbable   = false
  end

  # Set by the tree or folder holding this file, before it draws it.
  def place(level:, guides:, tabbable: false)
    @level    = level
    @guides   = guides
    @tabbable = tabbable
  end

  def active? = @active
  def link? = @href.present?
  def tag_name = link? ? :a : :span

  def row_attrs
    attrs = @html_attrs.except(:data, :aria)
    attrs[:href]     = @href if link?
    attrs[:role]     = "treeitem"
    attrs[:tabindex] = @tabbable ? 0 : -1
    attrs[:class]    = cn(UI::FileTree::ROW, @user_class)
    attrs[:aria]     = { selected: @active.to_s, level: @level, current: ("page" if @active && link?) }
                         .compact.merge(@html_attrs[:aria] || {})
    attrs[:data]     = { slot: "file-tree-file", name: @name, value: @value, "ui--file-tree-target": "item" }
                         .merge(@html_attrs[:data] || {})
    attrs
  end
end
