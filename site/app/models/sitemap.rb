# The pages search engines should know about, and when each last changed.
#
# Dates live in config/lastmod.yml, written by `bin/rails seo:lastmod` from
# git history. They can't be worked out at runtime or build time: the Docker
# build context leaves out .git, and a deploy clone is shallow. A page with no
# date is still listed, just without <lastmod>; test/integration/seo_test.rb
# fails when that happens, so a new page or component gets one.
class Sitemap
  LASTMOD_FILE = Rails.root.join("config/lastmod.yml")

  class << self
    include Rails.application.routes.url_helpers

    def paths
      [ root_path, docs_path ] +
        DocsController::PAGES.keys.excluding("getting_started").map { |page| doc_path(page) } +
        ChartsController::PAGES.keys.map { |page| ChartsController.path_for(page) } +
        [ components_path ] + ComponentDoc.names.map { |name| component_path(name) }
    end

    def lastmod(path)
      dates[path]
    end

    # The files whose last commit dates a page: what you read on it, not the
    # layout every page shares (a header tweak isn't a content change).
    # Paths are relative to the repository root.
    def sources(path)
      case path
      when root_path then [ "site/app/views/pages" ]
      when docs_path then [ "site/app/views/docs/getting_started.html.erb" ]
      when components_path then [ "site/app/views/components/index.html.erb" ]
      when charts_path then chart_sources("overview")
      when %r{\A/docs/charts/([a-z_]+)\z} then chart_sources(Regexp.last_match(1))
      when %r{\A/docs/components/([a-z_]+)\z} then component_sources(Regexp.last_match(1))
      when %r{\A/docs/([a-z_]+)\z} then Dir.glob("site/app/views/docs/#{Regexp.last_match(1)}{.html.erb,/**/*}", base: repo_root)
      else []
      end
    end

    def repo_root = Rails.root.join("..")

    private

    def chart_sources(page)
      Dir.glob("site/app/views/charts/{#{page}.html.erb,examples/#{page}/*}", base: repo_root)
    end

    def component_sources(name)
      registry = Velvetkit.registry
      files = registry.component_files(name) + registry.javascript_files(name) + registry.preview_files(name)
      files.map { |file| "registry/#{file}" }
    end

    def dates
      @dates = nil if Rails.env.development?
      @dates ||= LASTMOD_FILE.exist? ? YAML.load_file(LASTMOD_FILE) || {} : {}
    end
  end
end
