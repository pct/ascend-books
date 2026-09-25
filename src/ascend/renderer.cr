require "ecr"
require "html"
require "json"

module Ascend
  # ECR 模板：templates/layouts、templates/components、templates/pages。
  class Renderer
    getter config : Config
    getter collection : Collection

    def initialize(@config : Config, @collection : Collection)
    end

    # ── 頁面 ───────────────────────────────────────────────

    def index : String
      books = collection.books
      body = ECR.render("#{__DIR__}/../../templates/pages/index.ecr")
      layout(title: "#{config.title}｜#{config.subtitle}", description: config.description, path: "/", body: body)
    end

    def book(book : Book) : String
      body = ECR.render("#{__DIR__}/../../templates/pages/book.ecr")
      layout(
        title: "《#{book.title}》#{book.author}｜#{config.title}",
        description: book.description,
        path: book.url, body: body, og_type: "article", json_ld: book_json_ld(book),
      )
    end

    def tags_index : String
      tags = collection.tags
      body = ECR.render("#{__DIR__}/../../templates/pages/tags.ecr")
      layout(title: "標籤｜#{config.title}", description: "#{config.title} 的全部標籤", path: "/tags/", body: body)
    end

    def tag(tag : String, books : Array(Book)) : String
      body = ECR.render("#{__DIR__}/../../templates/pages/tag.ecr")
      layout(title: "##{tag}｜#{config.title}", description: "標籤 #{tag} 下的 #{books.size} 本書", path: Ascend.tag_url(tag), body: body)
    end

    def page(page : Page) : String
      body = ECR.render("#{__DIR__}/../../templates/pages/page.ecr")
      layout(title: "#{page.title}｜#{config.title}", description: page.description, path: page.url, body: body)
    end

    def not_found : String
      body = ECR.render("#{__DIR__}/../../templates/pages/404.ecr")
      layout(title: "找不到頁面｜#{config.title}", description: "404", path: "/404.html", body: body)
    end

    # ── 元件 ───────────────────────────────────────────────

    def navbar(current : String) : String
      ECR.render("#{__DIR__}/../../templates/components/navbar.ecr")
    end

    def footer : String
      ECR.render("#{__DIR__}/../../templates/components/footer.ecr")
    end

    def book_row(book : Book) : String
      ECR.render("#{__DIR__}/../../templates/components/book_row.ecr")
    end

    def tag_chips(tags : Array(String), small : Bool = false) : String
      ECR.render("#{__DIR__}/../../templates/components/tag_chips.ecr")
    end

    def rating_stars(rating : Int32) : String
      ECR.render("#{__DIR__}/../../templates/components/rating.ecr")
    end

    # ── 工具 ───────────────────────────────────────────────

    def h(value) : String
      HTML.escape(value.to_s)
    end

    def tag_url(tag : String) : String
      Ascend.tag_url(tag)
    end

    private def layout(title : String, description : String, path : String, body : String,
                       og_type : String = "website", json_ld : String? = nil) : String
      canonical = config.absolute(path)
      ECR.render("#{__DIR__}/../../templates/layouts/base.ecr")
    end

    private def book_json_ld(book : Book) : String
      JSON.build do |j|
        j.object do
          j.field "@context", "https://schema.org"
          j.field "@type", "Review"
          j.field "name", "《#{book.title}》讀書心得"
          j.field "url", config.absolute(book.url)
          j.field "datePublished", book.date_iso
          j.field "description", book.description
          j.field "inLanguage", "zh-Hant"
          j.field "author" { j.object { j.field "@type", "Person"; j.field "name", config.author } }
          if r = book.rating
            j.field "reviewRating" do
              j.object { j.field "@type", "Rating"; j.field "ratingValue", r; j.field "bestRating", 5; j.field "worstRating", 1 }
            end
          end
          j.field "itemReviewed" do
            j.object do
              j.field "@type", "Book"
              j.field "name", book.title
              j.field "author" { j.object { j.field "@type", "Person"; j.field "name", book.author } }
              if isbn = book.isbn
                j.field "isbn", isbn
              end
              if pub = book.publisher
                j.field "publisher", pub
              end
            end
          end
        end
      end.gsub("</", "<\\/")
    end
  end
end
