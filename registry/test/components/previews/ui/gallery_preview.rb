# frozen_string_literal: true

class UI::GalleryPreview < ViewComponent::Preview
  # Drawn here so the previews need no image files. The fine grid shows off zoom.
  PHOTOS = [ [ "Front", "#7c3aed", "#ede9fe" ], [ "Side", "#0f766e", "#ccfbf1" ], [ "Handle", "#b45309", "#fef3c7" ],
             [ "Base", "#be123c", "#ffe4e6" ], [ "In use", "#1d4ed8", "#dbeafe" ] ].freeze

  def self.photo(title, color, background, width: 1600, height: 1600)
    grid = (0..(width / 40)).map { |i| "<path d='M#{i * 40} 0V#{height}' stroke='#{color}' stroke-opacity='.15'/>" }.join +
           (0..(height / 40)).map { |i| "<path d='M0 #{i * 40}H#{width}' stroke='#{color}' stroke-opacity='.15'/>" }.join
    svg = "<svg xmlns='http://www.w3.org/2000/svg' width='#{width}' height='#{height}'>" \
          "<rect width='100%' height='100%' fill='#{background}'/>#{grid}" \
          "<circle cx='#{width / 2}' cy='#{height / 2}' r='#{[ width, height ].min / 4}' fill='#{color}'/>" \
          "<text x='50%' y='50%' dy='.35em' text-anchor='middle' font-family='sans-serif' " \
          "font-size='#{[ width, height ].min / 14}' fill='#fff'>#{title}</text></svg>"
    "data:image/svg+xml,#{ERB::Util.url_encode(svg)}"
  end

  def self.photos = PHOTOS.map { |title, color, background| [ title, photo(title, color, background) ] }

  # @label Playground
  # @param zoom select { choices: [overlay, hover] }
  # @param zoom_scale number { min: 1.5, max: 5, step: 0.5 }
  # @param aspect select { choices: [square, landscape, portrait] }
  # @param fit select { choices: [contain, cover] }
  # @param count number { min: 1, max: 5 }
  def playground(zoom: :overlay, zoom_scale: 2.5, aspect: :square, fit: :contain, count: 5)
    render(UI::Gallery.new(label: "Photos of the ceramic mug", zoom: zoom.to_sym, zoom_scale: zoom_scale.to_f,
                           aspect: aspect.to_sym, fit: fit.to_sym, class: "max-w-md")) do |gallery|
      self.class.photos.first(count.to_i).each { |title, src| gallery.with_image(src: src, alt: "Ceramic mug: #{title}") }
    end
  end

  # @label Overlay
  def product_page; render_with_template; end

  # @label Hover Zoom
  def hover_zoom; render_with_template; end

  # @label Landscape, Cropped to Fill
  def landscape; render_with_template; end

  # @label One Image
  def single; render_with_template; end
end
