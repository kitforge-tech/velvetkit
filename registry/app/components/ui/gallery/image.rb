# frozen_string_literal: true

# One image in a UI::Gallery. Holds what the gallery needs to draw it in three
# places (the main view, its thumbnail and the zoomed view); it draws nothing
# itself.
class UI::Gallery::Image < UI::Base
  attr_reader :src, :alt

  def initialize(src:, alt:, zoom_src: nil, thumbnail_src: nil)
    @src           = src
    @alt           = alt
    @zoom_src      = zoom_src
    @thumbnail_src = thumbnail_src
  end

  def zoom_src = @zoom_src || @src
  def thumbnail_src = @thumbnail_src || @src

  def call = nil
end
