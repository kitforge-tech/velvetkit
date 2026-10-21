module ApplicationHelper
  # Files the namespace playground rewrites, as velvetkit:add would.
  PLAYGROUND_FILES = %w[
    app/components/ui/dialog.rb
    app/components/ui/sheet.html.erb
    app/javascript/controllers/ui/theme_controller.ts
  ].freeze

  # What to paste into an AI agent to set VelvetKit up in an app.
  SETUP_PROMPT = <<~PROMPT.squish
    Set up VelvetKit in this Rails app. Add gem "velvetkit", group: :development
    to the Gemfile, run bundle install, then run bin/rails generate velvetkit:install.
    Read https://velvetkit.com/llms.txt, then add the components this app needs
    with bin/rails generate velvetkit:add and use them for all new UI.
  PROMPT

  # wrap: for prose, like prompts, rather than code. language: when neither
  # the label nor the code says what it is.
  def code_block(source, label: nil, wrap: false, language: nil)
    source = source.strip
    html = highlight(source, language || language_for(source, label, wrap))
    render "shared/code", html: html, label: label, wrap: wrap
  end

  # Prose stays plain. Otherwise the label's file name decides, then the
  # command itself: most unlabelled blocks are a line to run.
  def language_for(source, label, wrap)
    return "plaintext" if wrap

    lexer = label && Rouge::Lexer.guess_by_filename(File.basename(label))
    return lexer.tag if lexer && lexer.tag != "plaintext"

    case source
    when %r{\A(bin/|bundle |bun |npm |yarn |gem install )} then "shell"
    when /\Agem "/ then "ruby"
    else "plaintext"
    end
  end

  def highlight(source, language)
    lexer = Rouge::Lexer.find(language) || Rouge::Lexers::PlainText
    Rouge::Formatters::HTML.new.format(lexer.lex(source)).html_safe # rubocop:disable Rails/OutputSafety -- Rouge escapes the source
  end

  # Code shown on a guide page that would be ERB itself, so can't sit inline.
  def snippet(name)
    File.read(Rails.root.join("app/views/docs/snippets/#{name}.txt"))
  end

  # An SVG from app/assets/images, inline so it can take currentColor.
  def inline_svg(name, **attributes)
    svg = Rails.root.join("app/assets/images", name).read
    attrs = attributes.map { |key, value| %(#{key.to_s.dasherize}="#{ERB::Util.html_escape(value)}") }.join(" ")
    svg.sub("<svg ", "<svg #{attrs} ").html_safe # rubocop:disable Rails/OutputSafety -- our own asset
  end

  # Links that open an AI chat already asking about a page.
  def ask_ai_links(markdown_url, topic)
    prompt = "Read #{markdown_url} and help me use #{topic} from VelvetKit in my Rails app."
    {
      "Claude" => "https://claude.ai/new?q=#{ERB::Util.url_encode(prompt)}",
      "ChatGPT" => "https://chatgpt.com/?q=#{ERB::Util.url_encode(prompt)}"
    }
  end

  # A sidebar link. The current page gets a velvet bar on its left as well as
  # a tint, so it stands out while scanning a long list.
  def nav_link(text, path)
    current = current_page?(path)
    link_to text, path, aria: { current: current ? "page" : nil },
            class: [ "relative block rounded-md px-3 py-1.5 text-sm transition-all focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-1",
                     current ? "bg-primary/10 font-medium text-primary before:absolute before:inset-y-1.5 before:left-0 before:w-0.5 before:rounded-full before:bg-primary dark:bg-primary/20 dark:text-foreground dark:before:bg-[#c9a3f2]" : "text-muted-foreground hover:bg-accent hover:text-foreground" ]
  end

  # Which top-level section the page belongs to, for the header's current link.
  def section
    path = request.path
    return :lookbook if path.start_with?("/lookbook")
    return :components if path.start_with?("/docs/components")
    return :ai if path == doc_path("ai")
    return :docs if path.start_with?("/docs")

    nil
  end

  # Header links: ghost buttons, the current section filled in.
  def header_link_options(name, href)
    current = section == name
    { href: href, variant: :ghost, size: :sm, button_variant: true, aria: { current: current ? "page" : nil },
      class: current ? "bg-accent text-foreground" : "text-muted-foreground hover:text-foreground" }
  end

  # The namespace typed into the playground, or the error it raises.
  def playground_namespace(name)
    [ Velvetkit::Namespace.new(name.presence || "Kit"), nil ]
  rescue Velvetkit::Error => error
    [ nil, error.message ]
  end

  # A file as the add generator would write it: rewritten path and source,
  # trimmed to the code a reader cares about.
  def rewritten(namespace, file)
    source = Velvetkit.registry.read(file)
    source = source[/^class .*/m] || source if file.end_with?(".rb")
    source = source[/^export default .*/m] || source if file.end_with?(".ts")
    [ namespace.rewrite_path(file), namespace.rewrite(source).lines.first(18).join ]
  end
end
