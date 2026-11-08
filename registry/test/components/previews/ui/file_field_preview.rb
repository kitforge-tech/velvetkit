# frozen_string_literal: true

class UI::FileFieldPreview < ViewComponent::Preview
  # A stand-in for an Active Storage attachment: what UI::FileField reads to
  # show a file the record already has.
  KeptFile = Struct.new(:signed_id, :filename, :byte_size, :content_type, :url, keyword_init: true)

  def self.photo(title, color)
    svg = "<svg xmlns='http://www.w3.org/2000/svg' width='600' height='600'><rect width='100%' height='100%' fill='#{color}'/>" \
          "<text x='50%' y='50%' dy='.35em' text-anchor='middle' font-family='sans-serif' font-size='64' fill='#fff'>#{title}</text></svg>"
    "data:image/svg+xml,#{ERB::Util.url_encode(svg)}"
  end

  def self.kept_photos
    [ [ "Front", "#793cbb" ], [ "Side", "#1baf7a" ] ].map.with_index do |(title, color), index|
      KeptFile.new(signed_id: "kept-#{index}", filename: "mug-#{title.downcase}.svg", byte_size: 182_000 + (index * 41_000),
                   content_type: "image/svg+xml", url: photo(title, color))
    end
  end

  # @label Playground
  # @param label text
  # @param hint text
  # @param multiple toggle
  # @param preview toggle
  # @param direct_upload toggle
  # @param disabled toggle
  def playground(label: "Photos", hint: "PNG or JPG, up to 5 MB", multiple: true, preview: true, direct_upload: false,
                 disabled: false)
    render(UI::FileField.new(label: label, hint: hint, multiple: multiple, preview: preview, direct_upload: direct_upload,
                             disabled: disabled, accept: "image/*", max_size: 5.megabytes, name: "photos"))
  end

  # @label Product Photos, Uploaded Straight Away
  def product_photos; render_with_template; end

  # @label One Image
  def single_image; render_with_template; end

  # @label Names Only, No Previews
  def multiple_files; render_with_template; end

  # @label With Error
  def with_error; render_with_template; end
end
