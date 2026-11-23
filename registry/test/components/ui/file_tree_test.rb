# frozen_string_literal: true

require "test_helper"

class UI::FileTreeTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_project(active: false, open: nil, **opts)
    render_inline(UI::FileTree.new(**opts)) do |tree|
      tree.with_folder(name: "app", open: open) do |app|
        app.with_folder(name: "models") do |models|
          models.with_file(name: "user.rb", href: "/blob/app/models/user.rb", active: active)
        end
        app.with_file(name: "application.rb", href: "/blob/app/application.rb")
      end
      tree.with_file(name: "README.md", href: "/blob/README.md")
    end
  end

  def test_renders_a_labelled_tree_wired_to_its_controller
    render_project
    assert_selector "ul[role='tree'][aria-label='Files'][data-slot='file-tree'][data-controller='ui--file-tree']"
    assert_selector "ul[role='tree'][data-action='click->ui--file-tree#click keydown->ui--file-tree#keydown']"
  end

  def test_label_names_the_tree
    render_project(label: "Project files")
    assert_selector "ul[role='tree'][aria-label='Project files']"
  end

  def test_rows_are_treeitems_in_the_order_given
    render_project
    assert_equal %w[app models user.rb application.rb README.md],
                 page.all("[role='treeitem']", visible: :all).map { |row| row["data-name"] }
    assert_selector "li[role='none'] > [role='treeitem']", count: 5, visible: :all
    assert_selector "[role='treeitem'][data-ui--file-tree-target='item']", count: 5, visible: :all
  end

  def test_rows_carry_their_level
    render_project
    { "app" => 1, "models" => 2, "user.rb" => 3, "application.rb" => 2, "README.md" => 1 }.each do |name, level|
      assert_selector "[role='treeitem'][data-name='#{name}'][aria-level='#{level}']", visible: :all
    end
  end

  def test_only_the_first_row_is_in_the_tab_order
    render_project
    assert_selector "[role='treeitem'][tabindex='0']", count: 1
    assert_selector "[role='treeitem'][data-name='app'][tabindex='0']"
    assert_selector "[role='treeitem'][tabindex='-1']", count: 4, visible: :all
  end

  def test_a_folder_owns_its_group
    render_project
    folder = page.find("[data-slot='file-tree-folder'][data-name='app']")
    assert_selector "ul##{folder['aria-owns']}[role='group'][data-slot='file-tree-group']", visible: :all
    assert_selector "ul##{folder['aria-owns']} > li > [data-name='models']", visible: :all
  end

  def test_folders_start_closed
    render_project
    assert_selector "[data-name='app'][aria-expanded='false']"
    assert_selector "ul[role='group'][hidden][data-state='closed']", count: 2, visible: :all
    assert_no_selector "[data-name='README.md'][hidden]"
  end

  def test_an_open_folders_group_is_marked_open
    render_project(open: true)
    assert_selector "ul[role='group'][data-state='open']:not([hidden])", count: 1
  end

  def test_folders_holding_the_active_file_start_open
    render_project(active: true)
    assert_selector "[data-name='app'][aria-expanded='true']"
    assert_selector "[data-name='models'][aria-expanded='true']"
    assert_no_selector "ul[role='group'][hidden]", visible: :all
  end

  def test_open_decides_over_the_active_file
    render_project(active: true, open: false)
    assert_selector "[data-name='app'][aria-expanded='false']"
    render_project(open: true)
    assert_selector "[data-name='app'][aria-expanded='true']"
    assert_selector "[data-name='models'][aria-expanded='false']"
  end

  def test_a_file_with_an_href_is_a_link
    render_project
    assert_selector "a[role='treeitem'][href='/blob/README.md'][data-slot='file-tree-file']"
  end

  def test_the_active_link_is_the_current_page_and_selected
    render_project(active: true)
    assert_selector "a[data-name='user.rb'][aria-current='page'][aria-selected='true']"
    assert_selector "a[data-name='README.md'][aria-selected='false']"
    assert_no_selector "a[data-name='README.md'][aria-current]"
  end

  def test_a_file_without_an_href_is_a_row_to_pick
    render_inline(UI::FileTree.new) do |tree|
      tree.with_file(name: "notes.md", value: "docs/notes.md", active: true)
      tree.with_file(name: "todo.md")
    end
    assert_selector "span[role='treeitem'][data-name='notes.md'][data-value='docs/notes.md'][aria-selected='true']"
    assert_selector "span[role='treeitem'][data-name='todo.md'][data-value='todo.md'][aria-selected='false']"
    assert_no_selector "[aria-current]"
    assert_no_selector "a"
  end

  def test_folders_are_not_selectable
    render_project
    assert_no_selector "[data-slot='file-tree-folder'][aria-selected]", visible: :all
  end

  def test_icons
    render_project(active: true)
    assert_selector "[data-name='app'] svg[data-icon='chevron-right']"
    assert_selector "[data-name='app'] svg[data-icon='folder']"
    assert_selector "[data-name='README.md'] svg[data-icon='file']"
    assert_no_selector "[data-name='README.md'] svg[data-icon='chevron-right']"
  end

  def test_icon_swaps_the_icon
    render_inline(UI::FileTree.new) do |tree|
      tree.with_folder(name: "docs", icon: "book-open")
      tree.with_file(name: "notes.md", icon: "file-text")
    end
    assert_selector "[data-name='docs'] svg[data-icon='book-open']"
    assert_selector "[data-name='notes.md'] svg[data-icon='file-text']"
  end

  def test_a_files_block_shows_at_the_end_of_its_row
    render_inline(UI::FileTree.new) { |tree| tree.with_file(name: "user.rb") { "M" } }
    assert_selector "[data-name='user.rb'] > span:last-child", text: "M"
  end

  def test_guides_draw_a_line_down_open_folders
    render_project
    assert_selector "ul[role='group'].before\\:bg-border", count: 2, visible: :all
    render_project(guides: false)
    assert_no_selector "ul[role='group'].before\\:bg-border", visible: :all
    assert_selector "ul[role='group'].ps-5\\.5", count: 2, visible: :all
  end

  def test_a_guide_starts_below_its_folders_focus_ring
    render_project
    assert_selector "[data-slot='file-tree-folder'].peer\\/row + ul.peer-focus\\/row\\:before\\:top-1\\.5",
                    count: 2, visible: :all
  end

  def test_builds_from_data
    render_inline(UI::FileTree.new(items: [
      { name: "app", children: [
        { name: "models", children: [ { name: "user.rb", value: "app/models/user.rb", active: true } ] }
      ] },
      { "name" => "README.md", "href" => "/blob/README.md" }
    ]))
    assert_equal %w[app models user.rb README.md], page.all("[role='treeitem']").map { |row| row["data-name"] }
    assert_selector "[data-name='app'][aria-expanded='true']"
    assert_selector "[data-name='user.rb'][aria-level='3'][aria-selected='true'][data-value='app/models/user.rb']"
    assert_selector "a[data-name='README.md'][href='/blob/README.md']"
  end

  def test_an_empty_children_list_is_an_empty_folder
    render_inline(UI::FileTree.new(items: [ { name: "tmp", children: [] } ]))
    assert_selector "[data-slot='file-tree-folder'][data-name='tmp'][aria-expanded='false']"
  end

  def test_data_and_slots_together
    render_inline(UI::FileTree.new(items: [ { name: "Gemfile" } ])) { |tree| tree.with_file(name: "Rakefile") }
    assert_equal %w[Gemfile Rakefile], page.all("[role='treeitem']").map { |row| row["data-name"] }
  end

  def test_class_and_attributes_pass_through
    render_inline(UI::FileTree.new(class: "max-w-xs", id: "files", data: { turbo: false }, aria: { describedby: "hint" })) do |tree|
      tree.with_folder(name: "app", class: "font-semibold", id: "app-folder")
      tree.with_file(name: "README.md", class: "italic", data: { turbo_frame: "blob" })
    end
    assert_selector "ul#files.max-w-xs[role='tree'][data-turbo='false'][aria-describedby='hint'][aria-label='Files']"
    assert_selector "ul#files[data-controller='ui--file-tree']"
    assert_selector "span.font-semibold[data-name='app']"
    assert_selector "ul#app-folder-group[role='group']", visible: :all
    assert_selector "[data-name='app'][aria-owns='app-folder-group']"
    assert_selector "span.italic[data-name='README.md'][data-turbo-frame='blob'][data-ui--file-tree-target='item']"
  end
end
