# frozen_string_literal: true

# One image in a UI::Gallery. Holds what the gallery needs to draw it in three
# places (the main view, its thumbnail and the zoomed view); it draws nothing
# itself.
#
# In the zoomed view, `with_info` is shown in a panel beside the image, opened
# with the Info button (when it was taken, where, the camera), and each
# `with_action` is a button in the top bar (favourite, download, delete), for
# this image alone.
class UI::Gallery::Image < UI::Base
  attr_reader :src, :alt

  renders_one :info
  renders_many :actions

  def initialize(src:, alt:, zoom_src: nil, thumbnail_src: nil)
    @src           = src
    @alt           = alt
    @zoom_src      = zoom_src
    @thumbnail_src = thumbnail_src
  end

  def zoom_src = @zoom_src || @src
  def thumbnail_src = @thumbnail_src || @src

  # Runs the block given to `with_image`, which fills in the info and actions.
  # The gallery draws them where they go.
  def call
    content
    nil
  end
end
