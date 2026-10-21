# frozen_string_literal: true

class UI::AvatarGroupPreview < ViewComponent::Preview
  # @label Playground
  # @param count number { min: 1, max: 8 }
  # @param size  select { choices: [sm, default, lg, xl] }
  def playground(count: 4, size: :default)
    render(UI::AvatarGroup.new(size: size.to_sym)) do |group|
      INITIALS[0...count.to_i.clamp(1, 8)].each { |init| group.with_avatar { init } }
    end
  end

  INITIALS = %w[JD AS RM BK CD PK NP TW].freeze

  # @label Default Stack
  def default; render_with_template; end

  # @label With Overflow
  def overflow; render_with_template; end

  # @label Small Stack
  def small; render_with_template; end
end
