# frozen_string_literal: true

require "test_helper"

class UI::FileFieldTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def test_renders_a_file_input
    render_inline(UI::FileField.new)
    assert_selector "input[type='file']"
  end

  def test_input_is_screen_reader_only_not_hidden
    render_inline(UI::FileField.new)
    input = page.find("input", visible: :all)
    assert_includes input[:class].split, "sr-only"
    refute input[:hidden]
  end

  def test_dropzone_is_a_label_pointing_at_the_input
    render_inline(UI::FileField.new)
    label = page.find("label")
    input = page.find("input", visible: :all)
    assert_equal input[:id], label[:for]
  end

  def root = page.find("[data-controller='ui--file-field']")

  def test_controller_wraps_the_dropzone_and_takes_drops
    render_inline(UI::FileField.new)
    assert_selector "[data-controller='ui--file-field'] > label[data-ui--file-field-target='dropzone']"
    assert_includes root["data-action"], "dragover->ui--file-field#dragOver"
    assert_includes root["data-action"], "dragleave->ui--file-field#dragLeave"
    assert_includes root["data-action"], "drop->ui--file-field#drop"
  end

  def test_input_wired_to_the_controller_on_change
    render_inline(UI::FileField.new)
    input = page.find("input[type='file']", visible: :all)
    assert_includes input["data-action"], "change->ui--file-field#chosen"
  end

  def test_not_multiple_by_default
    render_inline(UI::FileField.new)
    refute page.find("input", visible: :all)[:multiple]
  end

  def test_multiple
    render_inline(UI::FileField.new(multiple: true))
    assert page.find("input", visible: :all)[:multiple]
  end

  def test_accept
    render_inline(UI::FileField.new(accept: "image/*"))
    assert_equal "image/*", page.find("input", visible: :all)[:accept]
  end

  def test_disabled
    render_inline(UI::FileField.new(disabled: true))
    assert page.find("input", visible: :all)[:disabled]
    assert_includes root[:class], "opacity-50"
  end

  def test_error_true_marks_the_input_invalid
    render_inline(UI::FileField.new(error: true))
    input = page.find("input", visible: :all)
    assert_equal "true", input["aria-invalid"]
    assert_includes root[:class], "border-destructive"
  end

  # --- form-builder binding (Rails convention) ---

  class User
    include ActiveModel::Model
    attr_accessor :avatar
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:user, record, vc_test_controller.view_context, {})
  end

  def test_form_binding_scopes_the_field_name
    render_inline(UI::FileField.new(form: form_builder_for(User.new), field: :avatar))
    assert_selector "input[type='file'][name='user[avatar]']"
  end

  def test_label_is_derived_from_the_attribute_name
    render_inline(UI::FileField.new(form: form_builder_for(User.new), field: :avatar))
    assert_selector "label", text: "Avatar"
  end

  def test_hint_renders
    render_inline(UI::FileField.new(hint: "PNG or JPG, up to 5MB"))
    assert_text "PNG or JPG, up to 5MB"
  end

  def test_html_attrs_passthrough
    render_inline(UI::FileField.new(id: "my-id", data: { test_id: "f" }))
    assert_selector "input#my-id[data-test-id='f']", visible: :all
  end

  # ── Previews ────────────────────────────────────────────────────────────

  def test_previews_by_default_with_a_list_and_a_tile_template
    render_inline(UI::FileField.new(name: "photos"))
    assert_equal "true", root["data-ui--file-field-preview-value"]
    assert_selector "ul[data-ui--file-field-target='list']", visible: :all
    template = rendered_content[%r{<template data-ui--file-field-target="template">.*?</template>}m]
    assert template, "no tile template"
    %w[thumb icon remove progress bar name meta retry].each { |role| assert_includes template, %(data-role="#{role}") }
  end

  def test_preview_false_lists_names_instead
    render_inline(UI::FileField.new(preview: false))
    assert_equal "false", root["data-ui--file-field-preview-value"]
    assert_selector "[data-ui--file-field-target='filenames']", visible: :all
    assert_no_selector "ul[data-ui--file-field-target='list']", visible: :all
  end

  def test_checks_accept_and_max_size_and_says_the_limit
    render_inline(UI::FileField.new(accept: "image/*", max_size: 5.megabytes))
    assert_equal "image/*", root["data-ui--file-field-accept-value"]
    assert_equal 5.megabytes.to_s, root["data-ui--file-field-max-size-value"]
    assert_equal "5 MB", JSON.parse(root["data-ui--file-field-labels-value"])["max"]
  end

  # ── Direct upload ───────────────────────────────────────────────────────

  def test_direct_upload_points_at_active_storage
    render_inline(UI::FileField.new(name: "photos", direct_upload: true))
    assert_equal "true", root["data-ui--file-field-direct-upload-value"]
    assert_match %r{/rails/active_storage/direct_uploads\z}, root["data-ui--file-field-url-value"]
  end

  def test_without_direct_upload_there_is_no_upload_url
    render_inline(UI::FileField.new(name: "photos"))
    assert_nil root["data-ui--file-field-url-value"]
  end

  def test_signed_ids_post_under_the_fields_name
    render_inline(UI::FileField.new(name: "product[photos]", multiple: true, direct_upload: true))
    assert_equal "product[photos][]", root["data-ui--file-field-name-value"]
    render_inline(UI::FileField.new(name: "store[logo]", direct_upload: true))
    assert_equal "store[logo]", root["data-ui--file-field-name-value"]
  end

  # ── Files already kept ──────────────────────────────────────────────────

  Kept = Struct.new(:signed_id, :filename, :byte_size, :content_type, :url, keyword_init: true)

  def kept
    [ Kept.new(signed_id: "abc", filename: "front.jpg", byte_size: 2_097_152, content_type: "image/jpeg", url: "/front.jpg"),
      Kept.new(signed_id: "def", filename: "manual.pdf", byte_size: 51_200, content_type: "application/pdf", url: "/manual.pdf") ]
  end

  def test_kept_files_show_as_tiles_kept_by_their_signed_ids
    render_inline(UI::FileField.new(name: "product[photos][]", multiple: true, existing: kept))
    tiles = page.all("ul li[data-ui--file-field-target='item'][data-state='kept']")
    assert_equal 2, tiles.size
    assert_selector "li input[type='hidden'][name='product[photos][]'][value='abc']", visible: :all
    assert_selector "li img[data-role='thumb'][src='/front.jpg']"
    assert_selector "li", text: "front.jpg"
    assert_selector "li", text: "2 MB"
    assert_selector "li button[aria-label='Remove manual.pdf']"
  end

  def test_a_kept_file_that_isnt_an_image_shows_an_icon
    render_inline(UI::FileField.new(name: "docs[]", multiple: true, existing: kept))
    pdf = page.all("li[data-ui--file-field-target='item']").last
    assert pdf.has_css?("img[data-role='thumb'][hidden]", visible: :all)
    assert pdf.has_css?("svg[data-icon='file']")
  end

  def test_a_kept_file_fills_a_required_field
    render_inline(UI::FileField.new(name: "photos[]", multiple: true, required: true, existing: kept))
    assert_nil page.find("input[type='file']", visible: :all)[:required]
    assert_equal "true", root["data-ui--file-field-required-value"]
    render_inline(UI::FileField.new(name: "photos[]", multiple: true, required: true))
    assert page.find("input[type='file']", visible: :all)[:required]
  end

  Product = Struct.new(:photos) do
    def to_model = self
    def model_name = ActiveModel::Name.new(self.class, nil, "Product")
    def persisted? = true
  end

  Many = Struct.new(:attachments)

  def test_bound_to_a_form_it_shows_the_records_attachments
    builder = ActionView::Helpers::FormBuilder.new(:product, Product.new(Many.new(kept)), vc_test_controller.view_context, {})
    render_inline(UI::FileField.new(form: builder, field: :photos, multiple: true))
    assert_selector "li input[type='hidden'][name='product[photos][]'][value='def']", visible: :all
    assert_equal "product[photos][]", root["data-ui--file-field-name-value"]
  end

  # ── The card ────────────────────────────────────────────────────────────

  def test_the_field_is_a_card_with_the_drop_area_inside
    render_inline(UI::FileField.new(name: "photos"))
    assert_includes root[:class], "rounded-xl"
    assert_includes root[:class], "bg-card"
    assert_selector "[data-controller='ui--file-field'] > label.border-dashed"
  end

  def test_the_hint_shows_in_the_card_and_describes_the_input
    render_inline(UI::FileField.new(hint: "PNG or JPG, up to 5MB"))
    hint = page.find("[id$='-requirements']", text: "PNG or JPG, up to 5MB")
    assert_includes page.find("input", visible: :all)["aria-describedby"], hint[:id]
    assert_no_selector "label + *", text: "PNG or JPG, up to 5MB"
  end

  def test_without_a_hint_the_card_says_what_the_field_takes
    render_inline(UI::FileField.new(accept: "image/*", max_size: 5.megabytes, multiple: true))
    assert_selector "[id$='-requirements']", text: "Images, up to 5 MB each"
    render_inline(UI::FileField.new(accept: ".pdf,.docx", max_size: 2.megabytes))
    assert_selector "[id$='-requirements']", text: "PDF, DOCX, up to 2 MB"
    render_inline(UI::FileField.new)
    assert_no_selector "[id$='-requirements']"
  end

  def test_rows_show_a_tick_once_uploaded_and_a_warning_on_error_by_their_state
    render_inline(UI::FileField.new(name: "docs[]", multiple: true, existing: kept))
    row = page.all("li[data-ui--file-field-target='item']").first
    assert row.has_css?("svg[data-icon='check'].group-data-\\[state\\=uploaded\\]\\:block", visible: :all)
    assert row.has_css?("svg[data-icon='circle-alert'].group-data-\\[state\\=error\\]\\:block", visible: :all)
  end
end
