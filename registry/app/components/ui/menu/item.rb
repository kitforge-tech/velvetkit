# frozen_string_literal: true

class UI::Menu::Item < UI::Base
  variants(
    base:
      "relative flex cursor-default select-none items-center gap-2 rounded w-full px-2 py-1 text-sm whitespace-nowrap border-0 bg-transparent outline-none transition-colors " \
      "hover:bg-accent hover:text-accent-foreground " \
      "focus:bg-accent focus:text-accent-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1 " \
      "aria-checked:bg-accent aria-checked:text-accent-foreground aria-checked:font-medium " \
      "data-[disabled]:pointer-events-none data-[disabled]:opacity-50 transition-all",
    variants: {
      variant: {
        default: "",
        destructive: "text-destructive hover:bg-destructive/10 hover:text-destructive focus:bg-destructive/10 focus:text-destructive"
      },
      inset: {
        true => "pl-8",
        false => ""
      }
    },
    defaults: { variant: :default, inset: false }
  )

  def initialize(label = nil, href: nil, disabled: false, variant: :default, inset: false, class: nil, **html_attrs, &block)
    @label = label
    @href = href
    @disabled = disabled
    @variant = variant
    @inset = inset
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @content_block = block
  end

  def classes
    cn(
      variant_classes(variant: @variant, inset: @inset),
      @user_class
    )
  end

  def html_options
    opts = @html_attrs.dup
    opts[:class] = classes
    opts[:role] ||= :menuitem
    opts[:tabindex] = -1
    opts[:"data-ui--menu-target"] = "item"
    opts[:disabled] = true if @disabled
    opts[:"data-disabled"] = true if @disabled
    opts
  end

  def tag_name
    @href ? :a : :button
  end

  def href_attr
    @href ? { href: @href } : {}
  end

  def render_label
    if @content_block
      captured = view_context.capture { view_context.instance_exec(&@content_block) }
      return captured if captured.present?
    end
    content.to_s.presence || @label.to_s
  end
end
