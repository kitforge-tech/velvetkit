# frozen_string_literal: true

class UI::AvatarGroup < UI::Base
  renders_many :avatars, ->(shape: :circle, size: :default, **opts, &block) {
    UI::Avatar.new(shape: shape, size: size, role: "listitem", class: "ring-2 ring-background", **opts, &block)
  }

  def initialize(max: 5, size: :default, class: nil, **html_attrs)
    @max        = max
    @size       = size
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
  end

  def classes
    cn("flex items-center -space-x-2", @user_class)
  end

  def visible_avatars
    avatars.first(@max)
  end

  def overflow_count
    [ avatars.size - @max, 0 ].max
  end

  def overflow_size_classes
    case @size
    when :sm      then "h-6 w-6 text-xs"
    when :default then "h-10 w-10 text-sm"
    when :lg      then "h-12 w-12 text-base"
    when :xl      then "h-16 w-16 text-lg"
    end
  end
end
