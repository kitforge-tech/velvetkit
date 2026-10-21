require "test_helper"

# Every page is well-formed HTML. A preview template with a stray end tag
# renders fine in Lookbook but closes the docs page's own layout early,
# spilling the rest of the page out of its column.
class HtmlTest < ActionDispatch::IntegrationTest
  test "every page parses without stray or misnested tags" do
    paths = [ root_path, docs_path, components_path ] +
            DocsController::PAGES.keys.excluding("getting_started").map { |page| doc_path(page) } +
            ComponentDoc.names.map { |name| component_path(name) }

    problems = paths.flat_map do |path|
      get path
      Nokogiri::HTML5(response.body, max_errors: 50).errors
              .map(&:to_s).grep(/End tag|isn't allowed|Unclosed/).map { |error| "#{path}: #{error.lines.first.strip}" }
    end
    assert_empty problems
  end
end
