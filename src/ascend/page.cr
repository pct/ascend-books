require "uri"

module Ascend
  # 獨立頁面（content/pages/<slug>.md）→ /<slug>/
  class Page
    getter slug : String
    getter title : String
    getter description : String
    getter html : String

    def initialize(@slug : String, @title : String, description : String = "", body : String = "")
      @html = Markdown.render(body).html
      @description = description.empty? ? Markdown.excerpt(body) : description
    end

    def url : String
      "/#{URI.encode_path_segment(slug)}/"
    end

    def out_path : String
      "#{slug}/index.html"
    end

    def self.parse(path : String, raw : String) : Page
      slug = File.basename(path, ".md")
      parsed = begin
        Frontmatter.split(raw)
      rescue e : Error
        raise ContentError.new(path, e.message || "front matter 錯誤")
      end
      title = parsed.data["title"]?.try(&.as_s?)
      raise ContentError.new(path, "缺少必填欄位 title") if title.nil? || title.empty?
      description = parsed.data["description"]?.try(&.as_s?) || ""
      new(slug, title, description, parsed.body)
    end

    def self.load_all(dir : String = "content/pages") : Array(Page)
      return [] of Page unless Dir.exists?(dir)
      errors = [] of ContentError
      pages = [] of Page
      Dir.glob(File.join(dir, "*.md")).sort.each do |path|
        next if File.basename(path).starts_with?('_')
        begin
          pages << Page.parse(path, File.read(path))
        rescue e : ContentError
          errors << e
        end
      end
      raise ContentErrors.new(errors) unless errors.empty?
      pages
    end
  end
end
