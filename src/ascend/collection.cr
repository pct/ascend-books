module Ascend
  # content/books 這個 collection：載入、驗證、排序、標籤索引。
  class Collection
    getter books : Array(Book)
    getter drafts_count : Int32

    def self.load(dir : String = "content/books", include_drafts : Bool = false) : Collection
      raise Error.new("找不到內容目錄 #{dir}") unless Dir.exists?(dir)
      errors = [] of ContentError
      books = [] of Book
      Dir.glob(File.join(dir, "*.md")).sort.each do |path|
        next if File.basename(path).starts_with?('_')
        begin
          books << Book.parse(path, File.read(path))
        rescue e : ContentError
          errors << e
        end
      end
      raise ContentErrors.new(errors) unless errors.empty?
      new(books, include_drafts)
    end

    def initialize(all : Array(Book), include_drafts : Bool = false)
      @drafts_count = all.count(&.draft)
      visible = include_drafts ? all : all.reject(&.draft)
      @books = visible.sort_by { |b| {-b.date.to_unix, b.title} }
      @books.each_with_index do |b, i|
        b.prev_book = @books[i + 1]?
        b.next_book = i > 0 ? @books[i - 1] : nil
      end
    end

    # [{標籤, 書}]，依數量多→少、再依名稱。
    def tags : Array({String, Array(Book)})
      h = Hash(String, Array(Book)).new { |hash, k| hash[k] = [] of Book }
      @books.each { |b| b.tags.each { |t| h[t] << b } }
      h.to_a.sort_by { |(t, bs)| {-bs.size, t} }
    end

    def by_tag(tag : String) : Array(Book)
      @books.select(&.tags.includes?(tag))
    end

    def count_by(status : Status) : Int32
      @books.count { |b| b.status == status }
    end
  end
end
