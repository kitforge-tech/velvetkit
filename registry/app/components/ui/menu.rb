# frozen_string_literal: true

class UI::Menu < UI::Base
  renders_one :trigger, ->(**opts) {
    UI::Menu::Trigger.new(**opts).tap { |t| t.set_menu_context(self) }
  }
  renders_one :menu_content, ->(**opts) {
    UI::Menu::Content.new(**opts).tap { |c| c.set_menu_context(self) }
  }
  alias_method :with_content, :with_menu_content

  def initialize(class: nil, **html_attrs)
    @user_class = binding.local_variable_get(:class)
    @html_attrs = html_attrs
    @id = @html_attrs[:id] || "ui-menu-#{SecureRandom.hex(4)}"
  end

  attr_reader :id

  def root_classes
    cn("relative inline-block", @user_class)
  end
end
