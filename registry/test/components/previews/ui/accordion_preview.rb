# frozen_string_literal: true

class UI::AccordionPreview < ViewComponent::Preview
  # @label Playground
  # @param type select { choices: [single, multiple] }
  def playground(type: :single)
    render(UI::Accordion.new(type: type.to_sym, default_value: "item-1")) do |accordion|
      accordion.with_item(value: "item-1") do |item|
        item.with_trigger { "Is it accessible?" }
        item.with_content do
          tag.p(class: "text-muted-foreground") { "Yes. It adheres to the WAI-ARIA design pattern." }
        end
      end
      accordion.with_item(value: "item-2") do |item|
        item.with_trigger { "Is it styled?" }
        item.with_content do
          tag.p(class: "text-muted-foreground") { "Yes. It comes with default styles that match the other components' aesthetic." }
        end
      end
    end
  end

  # @label Single (one open at a time)
  def single; render_with_template; end

  # @label Multiple (independent items)
  def multiple; render_with_template; end

  # @label FAQ Style
  def faq_style; render_with_template; end
end
