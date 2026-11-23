# frozen_string_literal: true

class UI::CarouselPreview < ViewComponent::Preview
  # @label Playground
  # @param count number { min: 1, max: 12 }
  # @param item_class select { choices: [w-48, w-64, basis-1/2, basis-1/3, basis-full] }
  # @param dots toggle
  def playground(count: 8, item_class: "w-48", dots: false)
    render(UI::Carousel.new(label: "Albums", item_class: item_class, dots: dots, class: "max-w-2xl")) do |carousel|
      UI::GalleryPreview.photos.cycle.first(count.to_i).each_with_index do |(title, src), index|
        carousel.with_item do
          tag.a(href: "#", class: "group block space-y-2 rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary") do
            image_tag(src, alt: "", class: "aspect-square w-full rounded-lg object-cover") +
              tag.span("#{title} #{index + 1}", class: "block text-sm font-medium group-hover:underline")
          end
        end
      end
    end
  end

  # @label Highlights
  def highlights; render_with_template; end

  # @label With dots
  def with_dots; render_with_template; end
end
