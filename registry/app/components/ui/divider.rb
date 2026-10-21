# frozen_string_literal: true

class UI::Divider < UI::Base
  variants(
    base: "shrink-0 border-border",
    variants: {
      orientation: {
        horizontal: "border-t w-full",
        vertical:   "border-l self-stretch h-full"
      }
    },
    defaults: { orientation: :horizontal }
  )

  def initialize(orientation: :horizontal, label: nil, class: nil, **html_attrs)
    @orientation = orientation.to_sym
    @label_text  = label
    @user_class  = binding.local_variable_get(:class)
    @html_attrs  = html_attrs
  end

  def label; @label_text; end

  def classes
    cn(variant_classes(orientation: @orientation), @user_class)
  end

  # Beside a label each rule takes half the leftover space; `w-full` on both
  # pushed the label and the second rule out of the row.
  def rule_classes
    cn(classes, "w-auto flex-1")
  end

  def wrapper_classes
    cn("flex items-center gap-3", @user_class) if label.present?
  end

  def label_classes
    "text-xs text-muted-foreground whitespace-nowrap"
  end
end
