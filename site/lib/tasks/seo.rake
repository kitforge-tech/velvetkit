namespace :seo do
  desc "Write config/lastmod.yml: when each sitemap page's content last changed, from git history"
  task lastmod: :environment do
    root = Sitemap.repo_root.to_s
    shallow = `git -C #{root.shellescape} rev-parse --is-shallow-repository`.strip
    abort "seo:lastmod needs full git history (this clone is shallow: git fetch --unshallow)" if shallow == "true"

    dates = Sitemap.paths.to_h do |path|
      sources = Sitemap.sources(path)
      abort "seo:lastmod: no source files for #{path}; add them to Sitemap.sources" if sources.empty?

      date = IO.popen([ "git", "-C", root, "log", "-1", "--format=%cs", "--", *sources ], &:read).strip
      abort "seo:lastmod: #{path}'s files have no commits yet; commit them first" if date.empty?

      [ path, date ]
    end

    header = "# When each sitemap page's content last changed. Written by `bin/rails seo:lastmod`;\n" \
             "# re-run it after changing a page or component and commit the result.\n"
    File.write(Sitemap::LASTMOD_FILE, header + dates.to_yaml)
    puts "Wrote #{dates.size} dates to #{Sitemap::LASTMOD_FILE.relative_path_from(Rails.root)}"
  end
end
