require "net/http"

# The newest velvetkit on RubyGems. Releases are published from a tag without
# a commit to main, so the gem's own VERSION can lag behind; this keeps the
# site's version badge on the latest release. Falls back to VERSION when
# RubyGems can't be reached, or when no URL is configured (tests).
class ReleasedVersion
  CACHE_KEY = "velvetkit/released-version"

  def self.current
    url = Rails.configuration.x.rubygems_latest_url
    return Velvetkit::VERSION if url.blank?

    Rails.cache.fetch(CACHE_KEY, expires_in: 15.minutes, skip_nil: true) { fetch(url) } || Velvetkit::VERSION
  end

  def self.fetch(url)
    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 2, read_timeout: 2) do |http|
      http.get(uri.request_uri)
    end
    parse(response.body) if response.is_a?(Net::HTTPSuccess)
  rescue StandardError => error
    Rails.logger.warn("ReleasedVersion: #{error.class}: #{error.message}")
    nil
  end

  # RubyGems' latest.json: {"version":"0.1.2.beta"}, or "unknown".
  def self.parse(body)
    version = JSON.parse(body)["version"]
    version if version.is_a?(String) && Gem::Version.correct?(version)
  rescue JSON::ParserError
    nil
  end
end
