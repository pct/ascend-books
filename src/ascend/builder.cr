require "file_utils"

module Ascend
  # 把整個站組到 out_dir（預設 dist/）。
  class Builder
    getter out_dir : String

    def initialize(@out_dir : String = "dist", @drafts : Bool = false, @minify : Bool = true,
                   @config_path : String = "site.yml", @public_dir : String = "public",
                   @quiet : Bool = false)
    end

    # 回傳是否成功。內容錯誤會全部列出後回 false。
    def build : Bool
      started = Time.instant
      config = Config.load(@config_path)
      collection = Collection.load(include_drafts: @drafts)
      pages = Page.load_all
      renderer = Renderer.new(config, collection)

      clean
      count = 0
      write("index.html", renderer.index); count += 1
      collection.books.each { |b| write(b.out_path, renderer.book(b)); count += 1 }
      write("tags/index.html", renderer.tags_index); count += 1
      collection.tags.each { |(t, bs)| write("tags/#{t}/index.html", renderer.tag(t, bs)); count += 1 }
      pages.each { |p| write(p.out_path, renderer.page(p)); count += 1 }
      write("404.html", renderer.not_found); count += 1
      write("rss.xml", Feeds.rss(config, collection.books))
      write("sitemap.xml", Feeds.sitemap(config, collection, pages))
      write("robots.txt", Feeds.robots(config)) unless File.exists?(File.join(@public_dir, "robots.txt"))
      copy_tree(@public_dir, out_dir) if Dir.exists?(@public_dir)
      css_ok = CSS.build(out_dir, @minify)

      ms = (Time.instant - started).total_milliseconds.round
      draft_note = collection.drafts_count > 0 && !@drafts ? "，略過 #{collection.drafts_count} 篇草稿" : ""
      log "✓ #{count} 頁、#{collection.books.size} 本書#{draft_note} → #{out_dir}/（#{ms} ms）"
      css_ok
    rescue e : ContentErrors
      e.errors.each { |err| STDERR.puts "  ✗ #{err.message}" }
      STDERR.puts "#{e.errors.size} 個內容錯誤，建置中止。"
      false
    rescue e : Error
      STDERR.puts "  ✗ #{e.message}"
      false
    end

    private def clean
      raise Error.new("拒絕清除輸出目錄 #{out_dir.inspect}") if {"", ".", "/", ".."}.includes?(out_dir) || out_dir.starts_with?("/")
      FileUtils.rm_rf(out_dir)
      Dir.mkdir_p(out_dir)
    end

    private def write(rel : String, content : String)
      path = File.join(out_dir, rel)
      Dir.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    private def copy_tree(src : String, dst : String)
      Dir.mkdir_p(dst)
      Dir.each_child(src) do |child|
        next if child == ".DS_Store"
        from = File.join(src, child)
        to = File.join(dst, child)
        if File.directory?(from)
          copy_tree(from, to)
        else
          File.copy(from, to)
        end
      end
    end

    private def log(msg : String)
      puts msg unless @quiet
    end
  end
end
