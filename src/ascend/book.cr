require "uri"

module Ascend
  enum Status
    Reading
    Done
    Wishlist

    def label : String
      case self
      in .reading?  then "在讀"
      in .done?     then "讀完"
      in .wishlist? then "想讀"
      end
    end

    def key : String
      to_s.downcase
    end
  end

  def self.tag_url(tag : String) : String
    "/tags/#{URI.encode_path_segment(tag)}/"
  end

  # 一篇讀書心得（content/books/<slug>.md）。
  class Book
    getter slug : String
    getter title : String
    getter author : String
    getter date : Time
    getter tags : Array(String)
    getter rating : Int32?
    getter status : Status
    getter publisher : String?
    getter year : Int32?
    getter isbn : String?
    getter cover : String?
    getter buy : Array({String, String})
    getter description : String
    getter draft : Bool
    getter html : String
    getter toc : Array(Markdown::Heading)
    getter word_count : Int32
    property prev_book : Book?
    property next_book : Book?

    def initialize(@slug : String, @title : String, @author : String, @date : Time,
                   @tags : Array(String) = [] of String, @rating : Int32? = nil,
                   @status : Status = Status::Done, @publisher : String? = nil,
                   @year : Int32? = nil, @isbn : String? = nil, @cover : String? = nil,
                   @buy : Array({String, String}) = [] of {String, String},
                   description : String = "", @draft : Bool = false, body : String = "")
      rendered = Markdown.render(body)
      @html = rendered.html
      @toc = rendered.toc
      @word_count = Markdown.word_count(body)
      @description = description.empty? ? Markdown.excerpt(body) : description
    end

    def url : String
      "/books/#{URI.encode_path_segment(slug)}/"
    end

    def out_path : String
      "books/#{slug}/index.html"
    end

    def date_iso : String
      date.to_s("%Y-%m-%d")
    end

    def date_human : String
      date.to_s("%Y/%m/%d")
    end

    def self.parse(path : String, raw : String) : Book
      slug = File.basename(path, ".md")
      parsed = begin
        Frontmatter.split(raw)
      rescue e : Error
        raise ContentError.new(path, e.message || "front matter 錯誤")
      end
      fm = parsed.data
      errors = [] of String

      title = string(fm, "title")
      errors << "缺少必填欄位 title" if title.nil? || title.empty?
      author = string(fm, "author")
      errors << "缺少必填欄位 author" if author.nil? || author.empty?

      date : Time? = nil
      case raw_date = fm["date"]?.try(&.raw)
      when Time
        date = Time.local(raw_date.year, raw_date.month, raw_date.day)
      when String
        begin
          date = Time.parse(raw_date, "%Y-%m-%d", Time::Location.local)
        rescue Time::Format::Error
          errors << "date 格式須為 YYYY-MM-DD（得到 #{raw_date.inspect}）"
        end
      when Nil
        errors << "缺少必填欄位 date"
      else
        errors << "date 格式須為 YYYY-MM-DD"
      end

      tags = [] of String
      if t = fm["tags"]?
        if arr = t.as_a?
          tags = arr.map { |v| v.as_s? || v.raw.to_s }.map(&.strip).reject(&.empty?)
        elsif s = t.as_s?
          tags = s.split(/[,，、]/).map(&.strip).reject(&.empty?)
        elsif !t.raw.nil?
          errors << "tags 須為陣列，例如 [道家, 內丹]"
        end
      end
      errors << "tags 不可含有 /" if tags.any?(&.includes?("/"))

      rating : Int32? = nil
      if r = fm["rating"]?
        v = r.as_i? || r.as_f?.try(&.to_i)
        if v && (1..5).includes?(v)
          rating = v
        else
          errors << "rating 須為 1–5 的整數（得到 #{r.raw.inspect}）"
        end
      end

      status = Status::Done
      if s = fm["status"]?
        if st = Status.parse?(s.raw.to_s)
          status = st
        else
          errors << "status 須為 reading / done / wishlist（得到 #{s.raw.inspect}）"
        end
      end

      year : Int32? = nil
      if y = fm["year"]?
        year = y.as_i? || y.raw.to_s.to_i?
        errors << "year 須為整數" if year.nil?
      end

      buy = [] of {String, String}
      if b = fm["buy"]?
        if hash = b.as_h?
          hash.each do |k, v|
            url = v.as_s? || v.raw.to_s
            if url.starts_with?("http")
              buy << {k.as_s? || k.raw.to_s, url}
            else
              errors << "buy 的 #{k} 必須是 http(s) 網址"
            end
          end
        elsif !b.raw.nil?
          errors << "buy 須為「店名: 網址」對應，例如 buy: { 博客來: https://..., momo: https://... }"
        end
      end

      draft = false
      if d = fm["draft"]?
        if b = d.as_bool?
          draft = b
        else
          errors << "draft 須為 true / false"
        end
      end

      raise ContentError.new(path, errors.join("；")) unless errors.empty?

      new(
        slug, title.not_nil!, author.not_nil!, date.not_nil!,
        tags: tags, rating: rating, status: status,
        publisher: string(fm, "publisher"), year: year,
        isbn: string(fm, "isbn"), cover: string(fm, "cover"), buy: buy,
        description: string(fm, "description") || "",
        draft: draft, body: parsed.body,
      )
    end

    private def self.string(fm : YAML::Any, key : String) : String?
      v = fm[key]?
      return nil if v.nil? || v.raw.nil?
      (v.as_s? || v.raw.to_s).strip
    end
  end
end
