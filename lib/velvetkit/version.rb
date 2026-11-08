# frozen_string_literal: true

module Velvetkit
  # Not the released version: the release workflow takes that from the tag
  # (v0.3.0 publishes 0.3.0) and writes it here on the runner only, so this
  # file can stay behind. See .github/workflows/release.yml.
  VERSION = "0.1.2.beta"
end
