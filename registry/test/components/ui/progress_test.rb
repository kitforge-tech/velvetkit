# frozen_string_literal: true

require "test_helper"

class UI::ProgressTest < ViewComponent::TestCase
  def setup_fixtures(*); end
  def teardown_fixtures(*); end

  def render_progress(**opts) = render_inline(UI::Progress.new(**opts))

  def test_renders_a_progressbar_filled_to_its_value
    render_progress(value: 40)
    assert_selector "[data-slot='progress'][data-controller='ui--progress']"
    assert_selector "[role='progressbar'][aria-valuemin='0'][aria-valuemax='100'][aria-valuenow='40'][aria-valuetext='40%']"
    assert_selector "[data-slot='progress-indicator'][style='width: 40%']"
  end

  def test_scales_to_max_and_says_it_with_value_text
    render_progress(value: 3, max: 12, value_text: "%{value} of %{max} files", show_value: true)
    assert_selector "[role='progressbar'][aria-valuenow='3'][aria-valuemax='12'][aria-valuetext='3 of 12 files']"
    assert_selector "[data-slot='progress-indicator'][style='width: 25%']"
    assert_selector "[data-ui--progress-target='text']", text: "3 of 12 files"
    assert_selector "[data-ui--progress-format-value='%{value} of %{max} files']"
  end

  def test_rounds_down_so_it_never_says_done_too_early
    render_progress(value: 99.7)
    assert_selector "[role='progressbar'][aria-valuetext='99%']"
    assert_selector "[data-slot='progress-indicator'][style='width: 99%']"
  end

  def test_keeps_the_value_inside_the_bar
    render_progress(value: 150)
    assert_selector "[role='progressbar'][aria-valuenow='100'][data-state='complete']"
    render_progress(value: -5)
    assert_selector "[role='progressbar'][aria-valuenow='0'][data-state='loading']"
  end

  def test_is_busy_until_complete
    render_progress(value: 50)
    assert_selector "[role='progressbar'][aria-busy='true'][data-state='loading']"
    render_progress(value: 100)
    assert_selector "[role='progressbar'][data-state='complete']"
    assert_no_selector "[aria-busy]"
  end

  def test_with_no_value_it_shows_work_going_on_without_an_amount
    render_progress(label: "Preparing your export", show_value: true)
    assert_selector "[role='progressbar'][data-state='indeterminate'][aria-busy='true']"
    assert_no_selector "[aria-valuenow]"
    assert_no_selector "[aria-valuetext]"
    assert_no_selector "[data-ui--progress-value-value]"
    assert_selector "[data-slot='progress-indicator'].animate-\\[velvetkit-progress_1\\.4s_ease-in-out_infinite\\]"
    assert_no_selector "[data-slot='progress-indicator'][style]"
    assert_selector "[data-ui--progress-target='text'].hidden"
  end

  def test_the_label_names_the_bar
    render_progress(value: 10, label: "Uploading report.pdf")
    id = page.find("span", text: "Uploading report.pdf")["id"]
    assert_selector "[role='progressbar'][aria-labelledby='#{id}']"
    assert_no_selector "[role='progressbar'][aria-label]"
  end

  def test_without_a_label_it_has_a_default_name_that_can_be_replaced
    render_progress(value: 10)
    assert_selector "[role='progressbar'][aria-label='Progress']"
    assert_no_selector "[data-slot='progress'] > div.flex"
    render_progress(value: 10, aria: { label: "Storage used" })
    assert_selector "[role='progressbar'][aria-label='Storage used']"
  end

  def test_value_is_shown_only_when_asked
    render_progress(value: 40, label: "Profile")
    assert_selector "[data-ui--progress-target='text'].hidden"
    render_progress(value: 40, label: "Profile", show_value: true)
    assert_selector "[data-ui--progress-target='text']:not(.hidden)", text: "40%"
  end

  def test_sizes_and_tones
    render_progress(value: 5, size: :lg, tone: :warning)
    assert_selector "[role='progressbar'].h-3.bg-amber-500\\/15"
    assert_selector "[data-slot='progress-indicator'].bg-amber-500"
    render_progress(value: 5, size: :nonsense, tone: :nonsense)
    assert_selector "[role='progressbar'].h-2.bg-primary\\/15"
  end

  def test_gives_the_controller_what_it_needs_to_move_the_bar
    render_progress(value: 2.5, max: 10)
    assert_selector "[data-ui--progress-value-value='2.5'][data-ui--progress-max-value='10']"
    assert_selector "[data-ui--progress-determinate-class][data-ui--progress-indeterminate-class]"
    assert_selector "[role='progressbar'][data-ui--progress-target='bar'] [data-ui--progress-target='indicator']"
  end

  def test_passes_class_and_attributes_through
    render_progress(value: 1, id: "upload", class: "max-w-sm", data: { turbo_permanent: true })
    assert_selector "#upload.w-full.max-w-sm[data-turbo-permanent][data-controller='ui--progress']"
  end
end
