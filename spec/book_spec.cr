require "./spec_helper"

describe Ascend::Book do
  it "parses all fields" do
    b = Ascend::Book.parse("content/books/pragmatic.md", sample_book_md(publisher: "AW", year: "1999", isbn: "9780135957059"))
    b.slug.should eq "pragmatic"
    b.title.should eq "The Pragmatic Programmer"
    b.author.should eq "David Thomas, Andrew Hunt"
    b.date.should eq Time.local(2026, 3, 15)
    b.tags.should eq ["programming", "career"]
    b.status.should eq Ascend::Status::Done
    b.rating.should eq 5
    b.publisher.should eq "AW"
    b.year.should eq 1999
    b.isbn.should eq "9780135957059"
    b.draft.should be_false
    b.html.should contain "<h2"
    b.word_count.should be > 0
  end

  it "defaults status to done, description to excerpt" do
    b = Ascend::Book.parse("x.md", sample_book_md(status: "", rating: ""))
    b.status.should eq Ascend::Status::Done
    b.rating.should be_nil
    b.description.should start_with "這本書改變了"
  end

  it "accepts unquoted yaml dates and comma-separated tags" do
    b = Ascend::Book.parse("x.md", "---\ntitle: T\nauthor: A\ndate: 2026-01-02\ntags: 道家, 內丹\n---\n正文")
    b.date.should eq Time.local(2026, 1, 2)
    b.tags.should eq ["道家", "內丹"]
  end

  it "builds encoded urls for cjk slugs" do
    b = Ascend::Book.parse("content/books/2026-靈界.md", sample_book_md)
    b.url.should eq "/books/2026-%E9%9D%88%E7%95%8C/"
    b.out_path.should eq "books/2026-靈界/index.html"
  end

  it "collects every validation error at once" do
    err = expect_raises(Ascend::ContentError) do
      Ascend::Book.parse("bad.md", "---\ndate: 2026/01/01\nrating: 9\nstatus: maybe\n---\n")
    end
    err.message.not_nil!.should contain "bad.md"
    err.message.not_nil!.should contain "title"
    err.message.not_nil!.should contain "author"
    err.message.not_nil!.should contain "date"
    err.message.not_nil!.should contain "rating"
    err.message.not_nil!.should contain "status"
  end

  it "parses buy links in order and validates urls" do
    b = Ascend::Book.parse("x.md", "---\ntitle: T\nauthor: A\ndate: 2026-01-02\nbuy:\n  博客來: https://www.books.com.tw/products/1\n  momo: https://www.momoshop.com.tw/goods/2\n---\n")
    b.buy.should eq [{"博客來", "https://www.books.com.tw/products/1"}, {"momo", "https://www.momoshop.com.tw/goods/2"}]
    expect_raises(Ascend::ContentError, /buy/) { Ascend::Book.parse("x.md", "---\ntitle: T\nauthor: A\ndate: 2026-01-02\nbuy:\n  momo: not-a-url\n---\n") }
  end

  it "rejects tags containing slashes" do
    expect_raises(Ascend::ContentError, %r{/}) { Ascend::Book.parse("x.md", sample_book_md(tags: "[a/b]")) }
  end

  it "wraps front matter errors with the path" do
    expect_raises(Ascend::ContentError, /x\.md/) { Ascend::Book.parse("x.md", "no front matter") }
  end
end

describe Ascend::Status do
  it "has labels" do
    Ascend::Status::Wishlist.label.should eq "想讀"
    Ascend::Status::Reading.key.should eq "reading"
  end
end

describe Ascend::Cover do
  it "builds the google books content url from an isbn" do
    Ascend::Cover.google_url("978-986-377-950-6").should eq "https://books.google.com/books/content?vid=ISBN9789863779506&printsec=frontcover&img=1&zoom=1"
  end

  it "recognises google's placeholder responses" do
    Ascend::Cover.placeholder?("image/png", "x" * 1269).should be_true
    Ascend::Cover.placeholder?("image/png", "x" * 9103).should be_true
    Ascend::Cover.placeholder?("image/jpeg", "x" * 500).should be_true
    Ascend::Cover.placeholder?("image/jpeg", "real cover bytes " * 1000).should be_false
  end
end
