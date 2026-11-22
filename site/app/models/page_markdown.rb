# A guide page as Markdown, for AI agents and "Copy as Markdown": the page's
# own <article>, rendered as usual and turned into Markdown here, so the
# Markdown can't drift from the page. Navigation (breadcrumb, pager), buttons
# and live demos are left out; mark anything else to leave out with
# data-markdown="skip".
class PageMarkdown
  # Hidden isn't skipped: a tab's code is hidden until its tab is chosen.
  SKIP = "nav, button, form, dialog, svg, script, style, template, [aria-hidden=true], [role=tablist], [role=status], " \
         "[role=tooltip], [data-markdown=skip]".freeze
  INLINE = %w[a abbr b br code em i img kbd small span strong time].freeze
  BLOCKS = %w[p h1 h2 h3 h4 ul ol pre table aside blockquote div section header].freeze

  def self.from_html(html, base_url:)
    new(html, base_url).to_s
  end

  def initialize(html, base_url)
    @base_url = base_url
    @article = Nokogiri::HTML5.fragment(html).at_css("article") || Nokogiri::HTML5.fragment(html)
  end

  def to_s
    # A question in an accordion is a button inside its heading: keep its words.
    @article.css("h1 button, h2 button, h3 button, h4 button").each { _1.replace(_1.text.squish) }
    @article.css(SKIP).each(&:remove)
    "#{block(@article).strip.gsub(/\n{3,}/, "\n\n")}\n"
  end

  private

  # A run of blocks, a blank line between each. Text and inline elements
  # side by side ("Run <code>add</code> again") make one paragraph.
  def block(node)
    node.children.slice_when { |a, b| inline?(a) != inline?(b) }.flat_map do |run|
      inline?(run.first) ? [ run.map { inline_node(_1) }.join.squish ] : run.map { block_node(_1) }
    end.reject(&:blank?).join("\n\n")
  end

  def inline?(node) = node.text? || (node.element? && INLINE.include?(node.name))

  def block_node(node)
    return inline(node).strip if node.text?
    return "" unless node.element?

    case node.name
    when "h1", "h2", "h3", "h4" then "#{'#' * node.name[1].to_i} #{inline(node).squish}"
    when "p" then inline(node).squish
    when "ul", "ol" then list(node)
    when "pre" then fence(node)
    when "table" then table(node)
    when "aside", "blockquote" then block(node).lines.map { |line| line.strip.empty? ? ">\n" : "> #{line}" }.join.chomp
    when "time", "span", "a", "code", "strong", "em", "b", "i" then inline_node(node).squish
    else code_block?(node) ? fence(node.at_css("pre"), node) : block(node)
    end
  end

  # One of the site's code blocks: a file name above a <pre>.
  def code_block?(node) = node["data-controller"] == "clipboard" && node.at_css("pre")

  def fence(pre, wrapper = nil)
    code = pre.at_css("code") || pre
    language = code["data-language"].presence_in(%w[ruby erb html shell yaml javascript typescript css json]) || ""
    label = wrapper&.css("div")&.first&.text&.squish
    heading = label.present? && label != pre.text.squish ? "#{label}:\n\n" : ""
    "#{heading}```#{language}\n#{code.text.chomp}\n```"
  end

  # A heading inside a step reads as the step's bold title, and steps with
  # more than one paragraph get a blank line between them.
  def list(node)
    items = node.css("> li").each_with_index.map do |item, index|
      marker = node.name == "ol" ? "#{index + 1}." : "-"
      body = item.element_children.any? { BLOCKS.include?(_1.name) } ? block(item) : inline(item).squish
      body = body.sub(/\A#+ (.+)$/, '**\1**')
      body = body.sub(/\A\d+\.\s+/, "") if node.name == "ol" # it says its number already
      first, *rest = body.lines
      ([ "#{marker} #{first.to_s.strip}" ] + rest.map { |line| line.strip.empty? ? "" : "   #{line.chomp}" }).join("\n")
    end
    items.join(items.any? { _1.include?("\n") } ? "\n\n" : "\n")
  end

  def table(node)
    rows = node.css("tr").map { |row| row.css("th, td").map { inline(_1).squish.gsub("|", "\\|") } }.reject(&:empty?)
    return "" if rows.empty?

    width = rows.map(&:size).max
    rows = rows.map { |row| row + [ "" ] * (width - row.size) }
    [ rows.first, Array.new(width, "---"), *rows.drop(1) ].map { "| #{_1.join(' | ')} |" }.join("\n")
  end

  def inline(node) = node.children.map { inline_node(_1) }.join

  def inline_node(child)
    return child.text.gsub(/\s+/, " ") if child.text?
    return "" unless child.element?

    case child.name
    when "code" then "`#{child.text}`"
    when "strong", "b" then "**#{inline(child).strip}**"
    when "em", "i" then "*#{inline(child).strip}*"
    when "br" then "\n"
    when "a"
      text = inline(child).squish
      href = child["href"].to_s
      href.blank? || href.start_with?("#") || text.empty? ? text : "[#{text}](#{absolute(href)})"
    when "img" then child["alt"].to_s
    else inline(child)
    end
  end

  def absolute(href) = href.start_with?("/") ? "#{@base_url}#{href}" : href
end
