# frozen_string_literal: true

require "active_support/core_ext/string"
require "active_support/core_ext/object/blank"

module Velvetkit
  # The Ruby module the components live under in the host app.
  #
  # The registry is written once, against `UI`. Every file is rewritten on the
  # way into the host, so `Kit` turns `UI::Button` into `Kit::Button`,
  # `app/components/ui/` into `app/components/kit/`, the `ui--dialog` Stimulus
  # identifier into `kit--dialog`, and the `ui.` I18n scope into `kit.`.
  class Namespace
    CANONICAL = "UI"
    FORMAT = /\A[A-Z][A-Za-z0-9]*\z/

    attr_reader :name

    def initialize(name)
      @name = name.to_s
      return if FORMAT.match?(@name)

      raise Error, "Namespace must be a single Ruby constant name like UI or Kit, got #{name.inspect}"
    end

    # True when Rails cannot get from the directory name back to the constant
    # without an inflection: `ui`.camelize is `Ui`, not `UI`.
    def acronym?
      name.underscore.camelize != name
    end

    # Directory name and I18n scope: UI → ui, VelvetKit → velvet_kit.
    def path
      acronym? ? name.downcase : name.underscore
    end

    # Prefix for Stimulus identifiers and DOM ids: VelvetKit → velvet-kit.
    def dom
      path.dasherize
    end

    def rewrite_path(file)
      file.gsub(%r{(?<=\A|/)ui(?=/)}, path)
    end

    def rewrite(source)
      source
        .gsub(/\bUI(?=::)/, name)                     # UI::Button
        .gsub(/\bmodule UI\b/, "module #{name}")      # module UI; end
        .gsub("ui--", "#{dom}--")                     # Stimulus identifiers
        .gsub(/(?<=["'`])ui-(?=[a-z`])/, "#{dom}-")   # DOM ids, storage keys
        .gsub(/(?<=["'`])ui\.(?=[a-z`])/, "#{path}.") # I18n keys
        .gsub(/^(\s+)ui:$/, "\\1#{path}:")            # locale file scope
        .gsub(%r{(?<=/)ui(?=/)}, path)                # controllers/ui/… paths
    end
  end
end
