# frozen_string_literal: true

require "test_helper"

class UI::TextareaTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  # ── Default render ───────────────────────────────────────────────────────────

  def test_renders_textarea_tag
    render_inline(UI::Textarea.new)
    assert_selector "textarea"
    refute_selector "div"
  end

  def test_default_rows
    render_inline(UI::Textarea.new)
    assert_selector "textarea[rows='3']"
  end

  def test_custom_rows
    render_inline(UI::Textarea.new(rows: 6))
    assert_selector "textarea[rows='6']"
  end

  def test_default_classes
    render_inline(UI::Textarea.new)
    classes = page.find("textarea")[:class].split
    assert_includes classes, "border-input"
    assert_includes classes, "text-sm"
    assert_includes classes, "resize-y"
  end

  # ── Sizes and resizing ───────────────────────────────────────────────────────

  def test_size_sm
    render_inline(UI::Textarea.new(size: :sm))
    assert_includes page.find("textarea")[:class].split, "text-xs"
  end

  def test_size_lg
    render_inline(UI::Textarea.new(size: :lg))
    assert_includes page.find("textarea")[:class].split, "text-base"
  end

  def test_resize_none
    render_inline(UI::Textarea.new(resize: :none))
    classes = page.find("textarea")[:class].split
    assert_includes classes, "resize-none"
    refute_includes classes, "resize-y"
  end

  def test_autogrow_sizes_to_content_and_cannot_be_dragged
    render_inline(UI::Textarea.new(autogrow: true))
    classes = page.find("textarea")[:class].split
    assert_includes classes, "field-sizing-content"
    assert_includes classes, "resize-none"
    refute_includes classes, "resize-y"
  end

  # ── Value ────────────────────────────────────────────────────────────────────

  def test_value_renders_as_content
    render_inline(UI::Textarea.new(value: "Hello\nworld"))
    assert_equal "Hello\nworld", page.find("textarea").value
  end

  def test_value_is_escaped
    render_inline(UI::Textarea.new(value: "</textarea><script>x</script>"))
    assert_selector "textarea", count: 1
    refute_selector "script"
  end

  # ── States ───────────────────────────────────────────────────────────────────

  def test_error_sets_aria_invalid_and_destructive_border
    render_inline(UI::Textarea.new(error: true))
    textarea = page.find("textarea[aria-invalid='true']")
    assert_includes textarea[:class].split, "border-destructive"
  end

  def test_no_error_no_aria_invalid
    render_inline(UI::Textarea.new)
    refute_selector "textarea[aria-invalid]"
  end

  def test_disabled
    render_inline(UI::Textarea.new(disabled: true))
    assert_selector "textarea[disabled]"
  end

  def test_required
    render_inline(UI::Textarea.new(required: true))
    assert_selector "textarea[required]"
  end

  # ── Attributes ───────────────────────────────────────────────────────────────

  def test_html_attrs_pass_through
    render_inline(UI::Textarea.new(name: "post[body]", id: "body", placeholder: "Write…", maxlength: 500))
    assert_selector "textarea#body[name='post[body]'][placeholder='Write…'][maxlength='500']"
  end

  def test_user_class_merges_via_tailwind_merge
    render_inline(UI::Textarea.new(class: "bg-muted max-h-60"))
    classes = page.find("textarea")[:class].split
    refute_includes classes, "bg-background"
    assert_includes classes, "bg-muted"
    assert_includes classes, "max-h-60"
  end

  # ── Label ────────────────────────────────────────────────────────────────────

  def test_label_is_a_linked_sibling
    render_inline(UI::Textarea.new(label: "Message"))
    assert_selector "div > label + textarea"
    assert_equal page.find("textarea")[:id], page.find("label")[:for]
    assert page.find("textarea")[:id].start_with?("ui-textarea-")
  end

  def test_explicit_id_is_linked
    render_inline(UI::Textarea.new(label: "Message", id: "msg"))
    assert_selector "label[for='msg'] + textarea#msg"
  end

  def test_required_label_shows_asterisk
    render_inline(UI::Textarea.new(label: "Message", required: true))
    assert_selector "label span.text-destructive", text: "*"
  end

  # ── Form builder ─────────────────────────────────────────────────────────────

  class Post
    include ActiveModel::Model
    attr_accessor :body
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:post, record, vc_test_controller.view_context, {})
  end

  def test_form_binding_scopes_name_and_fills_value
    render_inline(UI::Textarea.new(form: form_builder_for(Post.new(body: "Draft")), field: :body))
    textarea = page.find("textarea[name='post[body]']")
    assert_equal "Draft", textarea.value
    assert_includes textarea[:class].split, "border-input"
  end

  def test_form_binding_derives_linked_label
    render_inline(UI::Textarea.new(form: form_builder_for(Post.new), field: :body))
    assert_selector "label", text: "Body"
    assert_equal page.find("label")[:for], page.find("textarea")[:id]
  end

  def test_label_false_opts_out
    render_inline(UI::Textarea.new(form: form_builder_for(Post.new), field: :body, label: false))
    assert_no_selector "label"
  end
end
