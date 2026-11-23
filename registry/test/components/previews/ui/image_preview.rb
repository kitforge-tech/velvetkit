# frozen_string_literal: true

class UI::ImagePreview < ViewComponent::Preview
  # Drawn here so the previews need no image files. It fills its frame edge to
  # edge (`slice`), so the corners show the radius and the size reads at a glance.
  def self.photo
    svg = "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='300' viewBox='0 0 400 300' " \
          "preserveAspectRatio='xMidYMid slice'>" \
          "<defs><linearGradient id='sky' x2='0' y2='1'><stop stop-color='#c4b5fd'/><stop offset='1' stop-color='#fde68a'/>" \
          "</linearGradient></defs><rect width='400' height='300' fill='url(#sky)'/>" \
          "<circle cx='290' cy='110' r='42' fill='#f59e0b'/>" \
          "<path d='M0 300V190l90-80 70 60 80-90 90 100 70-50v170z' fill='#7c3aed'/>" \
          "<path d='M0 300V240l110-60 90 50 100-40 100 60v50z' fill='#4c1d95'/></svg>"
    "data:image/svg+xml,#{ERB::Util.url_encode(svg)}"
  end

  # @label Playground
  # @param rounded select { choices: [none, xs, sm, md, lg, xl, full] }
  # @param width text
  def playground(rounded: :sm, width: "160px")
    render(UI::Image.new(src: self.class.photo, alt: "Mountains at sunset", rounded: rounded.to_sym, width: width))
  end

  # @label Radii
  def radii; render_with_template; end

  # @label Sizing
  def sizing; render_with_template; end
end
