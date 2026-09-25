require "./spec_helper"

private def book(slug, date, tags = [] of String, draft = false, status = Ascend::Status::Done)
  Ascend::Book.new(slug, slug.capitalize, "A", Time.local(*date), tags: tags, draft: draft, status: status, body: "hi")
end

describe Ascend::Collection do
  it "sorts newest first and links prev/next" do
    c = Ascend::Collection.new([book("old", {2025, 1, 1}), book("new", {2026, 1, 1}), book("mid", {2025, 6, 1})])
    c.books.map(&.slug).should eq ["new", "mid", "old"]
    c.books[1].next_book.try(&.slug).should eq "new"
    c.books[1].prev_book.try(&.slug).should eq "old"
    c.books[0].next_book.should be_nil
    c.books[2].prev_book.should be_nil
  end

  it "hides drafts unless asked" do
    all = [book("a", {2026, 1, 1}), book("d", {2026, 1, 2}, draft: true)]
    Ascend::Collection.new(all).books.map(&.slug).should eq ["a"]
    Ascend::Collection.new(all).drafts_count.should eq 1
    Ascend::Collection.new(all, include_drafts: true).books.size.should eq 2
  end

  it "indexes tags by count then name" do
    c = Ascend::Collection.new([
      book("a", {2026, 1, 1}, ["道家", "內丹"]),
      book("b", {2026, 1, 2}, ["道家"]),
      book("c", {2026, 1, 3}, ["靈修"]),
    ])
    c.tags.map { |(t, bs)| {t, bs.size} }.should eq [{"道家", 2}, {"內丹", 1}, {"靈修", 1}]
    c.by_tag("道家").map(&.slug).should eq ["b", "a"]
  end

  it "counts by status" do
    c = Ascend::Collection.new([book("a", {2026, 1, 1}), book("w", {2026, 1, 2}, status: Ascend::Status::Wishlist)])
    c.count_by(Ascend::Status::Done).should eq 1
    c.count_by(Ascend::Status::Wishlist).should eq 1
  end

  it "loads from disk and aggregates errors" do
    dir = File.tempname("ascend-books")
    Dir.mkdir_p(dir)
    File.write("#{dir}/_template.md", "---\ntitle: 模板\n---\n")
    File.write("#{dir}/ok.md", sample_book_md)
    File.write("#{dir}/bad1.md", "---\ntitle: x\n---\n")
    File.write("#{dir}/bad2.md", "nope")
    err = expect_raises(Ascend::ContentErrors) { Ascend::Collection.load(dir) }
    err.errors.map(&.path).should eq ["#{dir}/bad1.md", "#{dir}/bad2.md"]
    File.delete("#{dir}/bad1.md")
    File.delete("#{dir}/bad2.md")
    Ascend::Collection.load(dir).books.map(&.slug).should eq ["ok"]
  ensure
    FileUtils.rm_rf(dir) if dir
  end
end
