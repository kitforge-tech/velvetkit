# frozen_string_literal: true

# A section that opens and closes under its trigger: a tree of links in a
# sidebar, "Show more" details, an advanced-settings block.
#
# Built on <details> and <summary>, so it works before any JavaScript loads,
# Enter and Space toggle it, screen readers announce it as expanded or
# collapsed, and find-in-page opens it to show a match. Browsers that can
# animate to auto height slide it open; the rest open it at once.
#
#   <%= render(UI::Collapsible.new(open: current_page_is_a_form?)) do |c| %>
#     <% c.with_trigger { "Forms" } %>
#     <%= link_to "Input", input_path %>
#   <% end %>
#
# Collapsibles nest, so a trigger inside the content makes a deeper branch.
class UI::Collapsible < UI::Base
  variants(
    base: "flex w-full cursor-pointer list-none items-center gap-2 rounded-md " \
          "[&::-webkit-details-marker]:hidden " \
          "#{UI::Base::FOCUS_RING}",
    variants: {
      size: {
        sm:      "px-2 py-1 text-xs",
        default: "px-3 py-1.5 text-sm",
        lg:      "px-3 py-2 text-base"
      }
    },
    defaults: { size: :default }
  )

  renders_one :trigger

  def initialize(open: false, size: :default, trigger_class: nil, content_class: nil,
                 class: nil, **html_attrs)
    @open          = open
    @size          = size
    @trigger_class = trigger_class
    @content_class = content_class
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
  end

  def details_options
    opts = @html_attrs.dup
    opts[:open]  = true if @open
    # interpolate-size lets the content's height transition to and from auto.
    opts[:class] = cn(
      "group/collapsible [interpolate-size:allow-keywords] " \
      "[&::details-content]:[block-size:0] [&::details-content]:overflow-hidden " \
      "[&::details-content]:transition-[block-size,content-visibility] " \
      "[&::details-content]:duration-200 [&::details-content]:[transition-behavior:allow-discrete] " \
      "open:[&::details-content]:[block-size:auto] " \
      "motion-reduce:[&::details-content]:transition-none",
      @user_class
    )
    opts
  end

  def trigger_classes
    cn(variant_classes(size: @size), @trigger_class)
  end

  def content_classes
    cn("pt-1", @content_class)
  end
end
