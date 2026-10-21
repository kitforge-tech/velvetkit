# frozen_string_literal: true

class UI::Avatar::Image < UI::Base
  def initialize(src:, alt: "", class: nil, **html_attrs)
    @src        = src
    @alt        = alt
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  attr_reader :src

  def classes
    cn("aspect-square h-full w-full object-cover", @user_class)
  end

  def call
    helpers.image_tag @src, alt: @alt, class: classes, **@html_attrs
  end
end
