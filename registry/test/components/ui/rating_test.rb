# frozen_string_literal: true

require "test_helper"

class UI::RatingTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  Review = Struct.new(:rating) do
    include ActiveModel::Validations
    def self.model_name = ActiveModel::Name.new(self, nil, "Review")
    validates :rating, presence: true
  end

  def form_builder_for(record)
    ActionView::Helpers::FormBuilder.new(:review, record, vc_test_controller.view_context, {})
  end

  # --- Shown ------------------------------------------------------------------

  def test_shows_a_score_as_one_named_image
    render_inline(UI::Rating.new(value: 4.5))
    assert_selector "[role='img'][aria-label='Rated 4.5 out of 5']"
    assert_no_selector "input"
    assert_no_selector "[role='radiogroup']"
  end

  def test_fills_to_the_nearest_half_star
    render_inline(UI::Rating.new(value: 3.7))
    assert_selector "[role='img'] > svg.text-amber-500", count: 3
    assert_selector "[role='img'] > span.relative", count: 1
    assert_selector "[role='img'] > span.relative > span.w-1\\/2.overflow-hidden svg"
    assert_selector "[role='img'] > svg.text-border.dark\\:text-muted", count: 1
  end

  def test_rounds_to_whole_stars_when_closer
    render_inline(UI::Rating.new(value: 4.2))
    assert_selector "[role='img'] > svg.text-amber-500", count: 4
    assert_no_selector "[role='img'] > span.relative"
    assert_selector "[role='img'][aria-label='Rated 4.2 out of 5']"
  end

  def test_no_score_is_five_empty_stars
    render_inline(UI::Rating.new)
    assert_selector "[role='img'][aria-label='Rated 0 out of 5'] > svg.text-border.dark\\:text-muted", count: 5
  end

  def test_a_score_out_of_range_is_held_to_it
    render_inline(UI::Rating.new(value: 7))
    assert_selector "[role='img'][aria-label='Rated 5 out of 5'] > svg.text-amber-500", count: 5
    render_inline(UI::Rating.new(value: -2))
    assert_selector "[role='img'][aria-label='Rated 0 out of 5']"
  end

  def test_a_score_given_as_a_string_or_decimal
    render_inline(UI::Rating.new(value: "3.5"))
    assert_selector "[role='img'][aria-label='Rated 3.5 out of 5']"
    render_inline(UI::Rating.new(value: BigDecimal("4.0")))
    assert_selector "[role='img'][aria-label='Rated 4 out of 5']"
  end

  def test_max_sets_how_many_stars
    render_inline(UI::Rating.new(value: 7, max: 10))
    assert_selector "[role='img'][aria-label='Rated 7 out of 10'] > svg", count: 10
  end

  def test_the_value_and_count_beside_the_stars
    render_inline(UI::Rating.new(value: 4.5, count: 1234, show_value: true))
    assert_selector "span[aria-hidden='true'].tabular-nums", text: "4.5"
    assert_selector "span[aria-hidden='true']", text: "(1,234)"
    assert_selector "span.sr-only", text: "1234 ratings"
  end

  def test_one_rating_is_singular
    render_inline(UI::Rating.new(value: 5, count: 1))
    assert_selector "span.sr-only", text: "1 rating"
  end

  def test_neither_value_nor_count_by_default
    render_inline(UI::Rating.new(value: 4))
    assert_no_selector ".tabular-nums"
    assert_no_selector ".sr-only"
  end

  def test_another_icon
    render_inline(UI::Rating.new(value: 2, icon: "circle-check"))
    assert_selector "svg[data-icon='circle-check']", count: 5
  end

  def test_sizes
    render_inline(UI::Rating.new(value: 2, size: :sm))
    assert_includes page.find("[role='img']")[:class].split, "[&_svg]:size-4"
    render_inline(UI::Rating.new(value: 2, size: :lg))
    assert_includes page.find("[role='img']")[:class].split, "[&_svg]:size-6"
  end

  def test_class_and_attributes_on_the_shown_score
    render_inline(UI::Rating.new(value: 4, class: "text-base", id: "score", data: { testid: "score" }))
    score = page.find("span#score[data-testid='score']")
    assert_includes score[:class].split, "text-base"
    refute_includes score[:class].split, "text-sm"
  end

  # --- Chosen -----------------------------------------------------------------

  def test_a_name_makes_it_a_radio_for_each_half_star
    render_inline(UI::Rating.new(name: "review[rating]", id: "rate"))
    assert_selector "div#rate[role='radiogroup'][aria-label='Rating'][data-controller='ui--rating']"
    expected = %w[0.5 1 1.5 2 2.5 3 3.5 4 4.5 5]
    actual = page.all("input[type='radio'][name='review[rating]']", visible: :all).map(&:value)
    assert_equal expected, actual
    assert_selector "label[for='rate-3'][data-ui--rating-target='star'] span.sr-only", text: "3 out of 5"
    assert_no_selector "[role='img']"
  end

  def test_a_half_star_value_checks_its_option
    render_inline(UI::Rating.new(name: "rating", value: 0.5))
    assert_equal [ "0.5" ], page.all("input[checked]", visible: :all).map(&:value)
  end

  def test_a_fractional_value_checks_the_nearest_half_star
    render_inline(UI::Rating.new(name: "rating", value: 3.6))
    assert_equal [ "3.5" ], page.all("input[checked]", visible: :all).map(&:value)
  end

  def test_each_half_star_is_lit_by_css_up_to_the_checked_one
    render_inline(UI::Rating.new(name: "rating"))
    classes = page.find("label", match: :first)[:class].split
    assert_includes classes, "[input:checked+&]:text-amber-500"
    assert_includes classes, "[&:has(~input:checked)]:text-amber-500"
    assert_includes classes, "data-[lit=true]:!text-amber-500"
  end

  # The stars draw no focus ring: the chosen score shows where the field is.
  def test_a_half_star_draws_no_focus_ring
    render_inline(UI::Rating.new(name: "rating"))
    classes = page.find("label", match: :first)[:class].split
    refute classes.any? { _1.include?("focus") || _1.include?("ring") || _1.include?("drop-shadow") }
  end

  # Both halves of a hovered star grow from its middle, so it grows as one.
  def test_a_hovered_star_grows_from_its_middle
    render_inline(UI::Rating.new(name: "rating"))
    start_half, end_half = page.all("label", minimum: 2).first(2).map { _1[:class].split }
    assert_includes start_half, "motion-safe:data-[hovered=true]:scale-125"
    assert_includes start_half, "origin-right"
    assert_includes start_half, "rtl:origin-left"
    assert_includes end_half, "origin-left"
    assert_includes end_half, "rtl:origin-right"
  end

  def test_each_radio_sits_before_its_half_star
    render_inline(UI::Rating.new(name: "rating", max: 3))
    expected = Array.new(6) { %w[input label] }.flatten
    actual = page.all("[role='radiogroup'] > *", visible: :all).map(&:tag_name)
    assert_equal expected, actual
  end

  def test_hover_reset_and_change_wiring
    render_inline(UI::Rating.new(name: "rating"))
    assert_selector "[data-action='mouseleave->ui--rating#reset reset@document->ui--rating#formReset']"
    assert_selector "label[data-action='mouseenter->ui--rating#preview']", count: 10
    assert_selector "input[data-action='change->ui--rating#choose']", count: 10, visible: :all
  end

  def test_label_names_the_field
    render_inline(UI::Rating.new(name: "rating", label: "Delivery"))
    assert_selector "[role='radiogroup'][aria-label='Delivery']"
  end

  def test_required_and_disabled
    render_inline(UI::Rating.new(name: "rating", required: true, disabled: true))
    assert_selector "input[required][disabled]", count: 10, visible: :all
    assert_selector "label.cursor-not-allowed.opacity-50", count: 10
  end

  # Choosing clears the error with JavaScript, so it needs the error's id.
  def test_the_error_to_clear_once_chosen
    render_inline(UI::Rating.new(name: "rating", legend: "Delivery", error: "Pick a score"))
    error_id = page.find("fieldset p", text: "Pick a score")[:id]
    assert_selector "[data-controller='ui--rating'][data-ui--rating-error-value='#{error_id}']"
  end

  def test_no_error_to_clear
    render_inline(UI::Rating.new(name: "rating", legend: "Delivery"))
    assert_no_selector "[data-ui--rating-error-value]"
  end

  def test_a_field_shows_its_score_beside_the_stars
    render_inline(UI::Rating.new(name: "rating", value: 3.5, show_value: true))
    score = page.find("output[aria-hidden='true']", text: "3.5/5")
    assert_selector "[data-ui--rating-score-value='#{score[:id]}']"
    assert_selector "label[data-value='4'][data-score='4/5']"
    assert_selector "label[data-value='4.5'][data-score='4.5/5']"
  end

  def test_a_field_with_no_score_shows_zero
    render_inline(UI::Rating.new(name: "rating", show_value: true))
    assert_selector "output", text: "0/5"
  end

  def test_a_field_shows_no_score_by_default
    render_inline(UI::Rating.new(name: "rating"))
    assert_no_selector "output"
    assert_no_selector "[data-ui--rating-score-value]"
    assert_no_selector "label[data-score]"
  end

  def test_thanks_show_once_chosen
    render_inline(UI::Rating.new(name: "rating", legend: "Delivery", thanks: true))
    thanks = page.find("p[role='status'][hidden].text-emerald-600", text: "Thank you for your rating", visible: :all)
    assert_selector "[data-ui--rating-thanks-value='#{thanks[:id]}']"
  end

  def test_thanks_in_your_words
    render_inline(UI::Rating.new(name: "rating", thanks: "Thanks, noted!"))
    assert_selector "p[role='status']", text: "Thanks, noted!", visible: :all
  end

  def test_no_thanks_by_default
    render_inline(UI::Rating.new(name: "rating"))
    assert_no_selector "p[role='status']", visible: :all
    assert_no_selector "[data-ui--rating-thanks-value]"
  end

  def test_a_legend_renders_through_fieldset
    render_inline(UI::Rating.new(name: "rating", legend: "Your rating", hint: "Out of five.", required: true, id: "r"))
    fieldset = page.find("fieldset[role='radiogroup'][aria-required='true']")
    assert fieldset[:"aria-labelledby"].present?
    assert_nil fieldset[:"aria-label"]
    assert_selector "legend", text: "Your rating"
    assert_selector "fieldset > p", text: "Out of five."
    assert_selector "fieldset > div#r:not([role])"
    assert_equal 1, page.all("[role='radiogroup']").size
  end

  def test_legend_true_without_a_form_still_names_it
    render_inline(UI::Rating.new(name: "rating", legend: true, hint: "Out of five."))
    assert_no_selector "legend"
    assert_selector "fieldset[role='radiogroup'][aria-label='Rating']"
  end

  def test_bound_to_a_form
    render_inline(UI::Rating.new(form: form_builder_for(Review.new(4)), field: :rating))
    assert_equal [ "4" ], page.all("input[name='review[rating]'][checked]", visible: :all).map(&:value)
    assert_no_selector "fieldset"
  end

  def test_bound_shows_the_models_errors_and_its_name
    render_inline(UI::Rating.new(form: form_builder_for(Review.new(nil).tap(&:validate)), field: :rating, legend: true))
    assert_selector "legend", text: "Rating"
    assert_selector "fieldset[role='radiogroup'][aria-invalid='true']"
    assert_selector "p.text-destructive", text: "Rating can't be blank"
    assert_no_selector "input[checked]", visible: :all
  end

  def test_class_and_attributes_on_the_stars
    render_inline(UI::Rating.new(name: "rating", class: "gap-2", data: { testid: "stars" }))
    stars = page.find("[role='radiogroup'][data-testid='stars'][data-controller='ui--rating']")
    assert_includes stars[:class].split, "gap-2"
  end

  def test_renders_no_whitespace_around_itself
    render_inline(UI::Rating.new(name: "rating"))
    assert rendered_content.start_with?("<div"), rendered_content[0, 20].inspect
    render_inline(UI::Rating.new(name: "rating", legend: "Rating"))
    assert rendered_content.start_with?("<fieldset"), rendered_content[0, 20].inspect
    render_inline(UI::Rating.new(value: 3))
    assert rendered_content.start_with?("<span"), rendered_content[0, 20].inspect
  end
end
