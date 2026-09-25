require "./spec_helper"

describe Ascend::Renderer do
  config = test_config
  b1 = Ascend::Book.parse("content/books/first.md", sample_book_md(title: "第一本 <b>", tags: "[道家]"))
  b2 = Ascend::Book.parse("content/books/second.md", sample_book_md(title: "第二本", date: "2026-04-01", status: "wishlist", rating: ""))
  collection = Ascend::Collection.new([b1, b2])
  r = Ascend::Renderer.new(config, collection)

  it "renders index with cards, stats and escaped titles" do
    html = r.index
    html.should contain "第一本 &lt;b&gt;"
    html.should contain %(data-search="第二本)
    html.should contain %(href="/books/second/")
    html.should contain %(<link rel="canonical" href="https://example.com/">)
    html.should contain "測試站"
  end

  it "renders a book page with meta, toc, rating, prev/next and json-ld" do
    html = r.book(b1)
    html.should contain %(<meta property="og:type" content="article">)
    html.should contain %(href="#為什麼讀")
    html.should contain "評分 5 / 5"
    html.should contain %(href="/books/second/") # prev (older? no: newer) navigation
    html.should contain %("@type":"Review")
    html.should contain %("ratingValue":5)
    html.should contain "第一本 &lt;b&gt;"
  end

  it "renders tag pages" do
    r.tags_index.should contain %(href="/tags/%E9%81%93%E5%AE%B6/")
    r.tag("道家", collection.by_tag("道家")).should contain %(href="/books/first/")
  end

  it "renders standalone pages and 404" do
    page = Ascend::Page.parse("content/pages/about.md", "---\ntitle: 關於\n---\n嗨 **你**")
    r.page(page).should contain "<strong>你</strong>"
    r.not_found.should contain "404"
  end
end

describe Ascend::Feeds do
  config = test_config
  b = Ascend::Book.parse("content/books/first.md", sample_book_md(tags: "[道家]"))
  collection = Ascend::Collection.new([b])

  it "writes rss with items" do
    rss = Ascend::Feeds.rss(config, collection.books)
    rss.should contain "<rss version=\"2.0\""
    rss.should contain "<link>https://example.com/books/first/</link>"
    rss.should contain "<category>道家</category>"
    rss.should contain "<content:encoded><![CDATA[<h2"
  end

  it "writes sitemap and robots" do
    page = Ascend::Page.new("about", "關於")
    sm = Ascend::Feeds.sitemap(config, collection, [page])
    sm.should contain "<loc>https://example.com/</loc>"
    sm.should contain "<loc>https://example.com/books/first/</loc>"
    sm.should contain "<loc>https://example.com/tags/%E9%81%93%E5%AE%B6/</loc>"
    sm.should contain "<loc>https://example.com/about/</loc>"
    Ascend::Feeds.robots(config).should contain "Sitemap: https://example.com/sitemap.xml"
  end
end
