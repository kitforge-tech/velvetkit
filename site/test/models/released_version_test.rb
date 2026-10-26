require "test_helper"

class ReleasedVersionTest < ActiveSupport::TestCase
  test "without a URL it is the gem's own version" do
    assert_nil Rails.configuration.x.rubygems_latest_url
    assert_equal Velvetkit::VERSION, ReleasedVersion.current
  end

  test "falls back to the gem's version when RubyGems can't be reached" do
    # Port 9 (discard) refuses at once, so this never waits on the network.
    Rails.configuration.x.rubygems_latest_url = "http://127.0.0.1:9/latest.json"
    assert_equal Velvetkit::VERSION, ReleasedVersion.current
  ensure
    Rails.configuration.x.rubygems_latest_url = nil
  end

  test "reads the version from RubyGems' latest.json" do
    assert_equal "0.1.2.beta", ReleasedVersion.parse('{"version":"0.1.2.beta"}')
  end

  test "ignores answers that aren't a version" do
    assert_nil ReleasedVersion.parse('{"version":"unknown"}')
    assert_nil ReleasedVersion.parse('{"version":null}')
    assert_nil ReleasedVersion.parse("<html>Service Unavailable</html>")
  end
end
