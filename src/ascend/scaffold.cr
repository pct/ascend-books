module Ascend
  module Scaffold
    DEFAULT_TEMPLATE = <<-MD
      ---
      title: 標題
      author: 作者
      date: 2026-01-01
      tags: []
      status: done
      ---

      ## 為什麼讀這本書

      ## 重點摘要

      ## 印象最深的段落

      MD

    # `ascend new "書名"` → content/books/YYYY-MM-DD-書名.md
    def self.new_book(title : String, author : String? = nil, dir : String = "content/books", today : Time = Time.local) : String
      title = title.strip
      raise Error.new("請提供書名：ascend new \"書名\"") if title.empty?
      date = today.to_s("%Y-%m-%d")
      safe = title.gsub(/\s+/, "-").gsub(%r{[/\\?%*:|"<>#]}, "")
      path = File.join(dir, "#{date}-#{safe}.md")
      raise Error.new("#{path} 已存在") if File.exists?(path)
      Dir.mkdir_p(dir)
      template_path = File.join(dir, "_template.md")
      content = File.exists?(template_path) ? File.read(template_path) : DEFAULT_TEMPLATE
      content = content.sub(/^title:[^\n]*/m, "title: #{title}")
      content = content.sub(/^date:[^\n]*/m, "date: #{date}")
      content = content.sub(/^author:[^\n]*/m, "author: #{author}") if author
      File.write(path, content)
      path
    end
  end
end
