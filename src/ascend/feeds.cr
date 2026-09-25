require "html"

module Ascend
  module Feeds
    def self.rss(config : Config, books : Array(Book), limit : Int32 = 20) : String
      String.build do |io|
        io << %(<?xml version="1.0" encoding="UTF-8"?>\n)
        io << %(<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">\n)
        io << "<channel>\n"
        io << "<title>" << HTML.escape(config.title) << "</title>\n"
        io << "<link>" << config.base_url << "/</link>\n"
        io << "<description>" << HTML.escape(config.description) << "</description>\n"
        io << "<language>zh-TW</language>\n"
        io << %(<atom:link href="#{config.absolute("/rss.xml")}" rel="self" type="application/rss+xml"/>\n)
        if latest = books.first?
          io << "<lastBuildDate>" << rfc2822(latest.date) << "</lastBuildDate>\n"
        end
        books.first(limit).each do |b|
          url = config.absolute(b.url)
          io << "<item>\n"
          io << "<title>" << HTML.escape("《#{b.title}》#{b.author}") << "</title>\n"
          io << "<link>" << url << "</link>\n"
          io << %(<guid isPermaLink="true">) << url << "</guid>\n"
          io << "<pubDate>" << rfc2822(b.date) << "</pubDate>\n"
          b.tags.each { |t| io << "<category>" << HTML.escape(t) << "</category>\n" }
          io << "<description>" << HTML.escape(b.description) << "</description>\n"
          io << "<content:encoded><![CDATA[" << b.html.gsub("]]>", "]]]]><![CDATA[>") << "]]></content:encoded>\n"
          io << "</item>\n"
        end
        io << "</channel>\n</rss>\n"
      end
    end

    def self.sitemap(config : Config, collection : Collection, pages : Array(Page)) : String
      today = Time.local.to_s("%Y-%m-%d")
      String.build do |io|
        io << %(<?xml version="1.0" encoding="UTF-8"?>\n)
        io << %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n)
        entry(io, config.absolute("/"), collection.books.first?.try(&.date_iso) || today)
        collection.books.each { |b| entry(io, config.absolute(b.url), b.date_iso) }
        entry(io, config.absolute("/tags/"), today)
        collection.tags.each { |(t, bs)| entry(io, config.absolute(Ascend.tag_url(t)), bs.first.date_iso) }
        pages.each { |p| entry(io, config.absolute(p.url), today) }
        io << "</urlset>\n"
      end
    end

    def self.robots(config : Config) : String
      "User-agent: *\nAllow: /\n\nSitemap: #{config.absolute("/sitemap.xml")}\n"
    end

    # 保留本地時區，避免 UTC 換算讓日期往前一天。
    private def self.rfc2822(t : Time) : String
      t.to_s("%a, %d %b %Y %H:%M:%S %z")
    end

    private def self.entry(io : IO, loc : String, lastmod : String)
      io << "<url><loc>" << HTML.escape(loc) << "</loc><lastmod>" << lastmod << "</lastmod></url>\n"
    end
  end
end
