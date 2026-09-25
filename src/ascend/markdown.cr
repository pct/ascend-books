require "markd"
require "html"

module Ascend
  module Markdown
    record Heading, level : Int32, id : String, text : String
    record Rendered, html : String, toc : Array(Heading)

    # Markdown → HTML，並替 h1–h6 加上 id、收集 h2/h3 做目錄。
    def self.render(md : String) : Rendered
      html = Markd.to_html(md)
      toc = [] of Heading
      used = Hash(String, Int32).new(0)
      html = html.gsub(/<h([1-6])>(.*?)<\/h\1>/m) do
        level = $~[1].to_i
        inner = $~[2]
        text = HTML.unescape(inner.gsub(/<[^>]+>/, "")).strip
        base = anchor(text)
        used[base] += 1
        id = used[base] > 1 ? "#{base}-#{used[base]}" : base
        toc << Heading.new(level, id, text) if level <= 4
        %(<h#{level} id="#{id}">#{inner}</h#{level}>)
      end
      Rendered.new(html, toc)
    end

    def self.anchor(text : String) : String
      a = text.downcase.gsub(/[^\p{L}\p{N}]+/, "-").strip('-')
      a.empty? ? "section" : a
    end

    # 去掉 Markdown 記號的純文字（做摘要、字數用）。
    def self.plain(md : String) : String
      md.gsub(/```.*?```/m, " ")
        .lines
        .map(&.strip)
        .reject(&.starts_with?("#"))
        .map { |l| l.sub(/^(?:[-+*]|\d+[.)])\s+/, "").sub(/^>\s?/, "").sub(/^\[[ xX]\]\s*/, "") }
        .join(" ")
        .gsub(/!\[[^\]]*\]\([^)]*\)/, "")
        .gsub(/\[([^\]]+)\]\([^)]*\)/, "\\1")
        .gsub(/<[^>]+>/, "")
        .gsub(/[*_`~]+/, "")
        .gsub(/\s+/, " ")
        .strip
    end

    def self.excerpt(md : String, limit : Int32 = 80) : String
      text = plain(md)
      chars = text.chars
      chars.size > limit ? chars[0, limit].join + "…" : text
    end

    # 字數：算字母與數字（中文每字一個），不算標點與空白。
    def self.word_count(md : String) : Int32
      plain(md).count(&.alphanumeric?)
    end
  end
end
