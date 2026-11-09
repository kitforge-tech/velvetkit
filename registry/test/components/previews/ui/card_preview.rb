# frozen_string_literal: true

class UI::CardPreview < ViewComponent::Preview
  # Drawn here so the previews need no image files.
  def self.photo(from, to)
    svg = "<svg xmlns='http://www.w3.org/2000/svg' width='800' height='450'>" \
          "<defs><linearGradient id='g' x2='1' y2='1'><stop stop-color='#{from}'/><stop offset='1' stop-color='#{to}'/>" \
          "</linearGradient></defs><rect width='800' height='450' fill='url(#g)'/>" \
          "<circle cx='620' cy='120' r='70' fill='#fff' fill-opacity='.35'/>" \
          "<path d='M0 450 240 210l150 140 110-90 300 190z' fill='#000' fill-opacity='.18'/></svg>"
    "data:image/svg+xml,#{ERB::Util.url_encode(svg)}"
  end

  # @label Playground
  # @param title text
  # @param description text
  # @param size select { choices: [default, sm] }
  # @param spacing select { choices: ["", 3, 4, 5, 6, 8] } "Blank follows the size"
  # @param show_action toggle
  # @param show_image toggle
  # @param show_footer toggle
  def playground(title: "Create project", description: "Deploy your new project in one click.", size: :default,
                 spacing: "", show_action: true, show_image: false, show_footer: true)
    render_with_template(locals: { title: title, description: description, size: size.to_sym,
                                   spacing: spacing.presence&.to_i, show_action: show_action,
                                   show_image: show_image, show_footer: show_footer })
  end

  # @label Sign In
  def sign_in; render_with_template; end

  # @label Small
  def small; render_with_template; end

  # @label With an Image
  def image; render_with_template; end

  # @label Stats, with a Badge as the Action
  def stats; render_with_template; end

  # @label Team, with a Button as the Action
  def team; render_with_template; end

  # @label Settings Form
  def settings_form; render_with_template; end

  # @label Spacing
  def spacing; render_with_template; end

  # @label Content to the Edges
  def edge_to_edge; render_with_template; end

  # @label Just Content
  def just_content; render_with_template; end

  # @label Open Bill at a Till
  def open_bill; render_with_template; end
end
