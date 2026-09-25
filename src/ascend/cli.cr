require "option_parser"

module Ascend
  module CLI
    def self.run(argv : Array(String)) : Nil
      args = argv.dup
      command = args.first?.try { |c| c.starts_with?('-') ? nil : args.shift }
      port = 4321
      out_dir = "dist"
      drafts = false
      author : String? = nil
      force = false

      parser = OptionParser.new do |p|
        p.banner = <<-TXT
          ascend #{VERSION} — Crystal 靜態站產生器

          用法:
            ascend build            建置到 dist/
            ascend dev              建置 + dev server + 監看重建
            ascend check            只驗證內容，不輸出
            ascend new "書名"        從 content/books/_template.md 建新的一篇
            ascend cover <file.md>  依 isbn 到 Google Books 找書封，寫進 cover:

          選項:
          TXT
        p.on("-p PORT", "--port PORT", "dev server 埠號（預設 4321）") { |v| port = v.to_i }
        p.on("-o DIR", "--out DIR", "輸出目錄（預設 dist）") { |v| out_dir = v }
        p.on("--drafts", "連 draft: true 的內容一起輸出（dev 預設開）") { drafts = true }
        p.on("-a NAME", "--author NAME", "new：作者") { |v| author = v }
        p.on("--force", "cover：已有 cover 也重新查並覆蓋") { force = true }
        p.on("-h", "--help", "說明") { puts p; exit 0 }
        p.on("-v", "--version", "版本") { puts VERSION; exit 0 }
        p.invalid_option { |flag| STDERR.puts "未知選項 #{flag}"; STDERR.puts p; exit 2 }
      end
      parser.parse(args)

      case command
      when "build"
        exit(Builder.new(out_dir: out_dir, drafts: drafts).build ? 0 : 1)
      when "check"
        exit(check ? 0 : 1)
      when "dev"
        dev(port, out_dir, argv)
      when "new"
        title = args.join(" ")
        begin
          path = Scaffold.new_book(title, author)
          puts "✓ 建立 #{path}"
        rescue e : Error
          STDERR.puts "✗ #{e.message}"
          exit 1
        end
      when "cover"
        if args.empty?
          STDERR.puts "用法：ascend cover content/books/xxx.md"
          exit 2
        end
        ok = true
        args.each do |path|
          begin
            ok = false unless Cover.apply(path, force)
          rescue e : Error
            STDERR.puts "  ✗ #{e.message}"
            ok = false
          end
        end
        exit(ok ? 0 : 1)
      when nil, "help"
        puts parser
      else
        STDERR.puts "未知指令 #{command.inspect}\n"
        STDERR.puts parser
        exit 2
      end
    end

    def self.check : Bool
      Config.load
      collection = Collection.load(include_drafts: true)
      pages = Page.load_all
      puts "✓ #{collection.books.size} 本書、#{pages.size} 頁，內容都通過驗證。"
      true
    rescue e : ContentErrors
      e.errors.each { |err| STDERR.puts "  ✗ #{err.message}" }
      false
    rescue e : Error
      STDERR.puts "  ✗ #{e.message}"
      false
    end

    def self.dev(port : Int32, out_dir : String, argv : Array(String)) : Nil
      builder = Builder.new(out_dir: out_dir, drafts: true, minify: false)
      builder.build
      server = Server.new(out_dir, port)
      server.start
      watcher = Watcher.new
      puts "  … 監看 content/ public/ src/styles/ templates/ src/（Ctrl-C 結束）"
      loop do
        sleep 0.5.seconds
        case watcher.poll
        when :rebuild
          puts "↻ 內容變動，重建…"
          builder.build
          server.bump
        when :recompile
          recompile_and_exec(server, argv)
        end
      end
    end

    private def self.recompile_and_exec(server : Server, argv : Array(String))
      puts "⟳ 模板／原始碼變動，重新編譯 bin/ascend…"
      Dir.mkdir_p("bin")
      status = Process.run("crystal", ["build", "src/main.cr", "-o", "bin/ascend"], output: :inherit, error: :inherit)
      if status.success?
        server.close
        Process.exec("bin/ascend", argv)
      else
        puts "✗ 編譯失敗，繼續用目前這版服務。"
      end
    end
  end
end
