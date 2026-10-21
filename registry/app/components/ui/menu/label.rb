# frozen_string_literal: true

class UI::Menu::Label < UI::Base
  def initialize(label = nil, inset: false, class: nil, **html_attrs, &block)
    @label = label
    @inset = inset
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @content_block = block
  end

  def classes
    cn(
      "px-2 py-1.5 text-sm font-semibold text-muted-foreground",
      { "pl-8" => @inset },
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:class] = classes
    opts
  end

  def render_label
    if @content_block
      captured = view_context.capture { view_context.instance_exec(&@content_block) }
      return captured if captured.present?
    end
    content.to_s.presence || @label.to_s
  end
end
