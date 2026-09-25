require "http/client"
require "digest/md5"

module Ascend
  # 依 ISBN 找書封：先試 Google Books（不用 API key 的 content endpoint），
  # 找不到就回 nil，讓使用者手動填其他站的網址。
  module Cover
    GOOGLE = "https://books.google.com/books/content?vid=ISBN%s&printsec=frontcover&img=1&zoom=1"
    # Google 對「有這本書但沒書封」回的是同一張灰底條紋 JPEG（2026-09 量到 10794 bytes）。
    PLACEHOLDER_MD5 = "d7c21c65fc861fc5128753e9e091b23c"

    def self.google_url(isbn : String) : String
      GOOGLE % isbn.gsub(/[^0-9Xx]/, "")
    end

    # 沒書封時 Google 仍回 200：查無 ISBN 是一張很小的 PNG，有書沒封面是固定的 JPEG 佔位圖。
    def self.lookup(isbn : String) : String?
      url = google_url(isbn)
      resp = HTTP::Client.get(url)
      return nil unless resp.status.success?
      placeholder?(resp.headers["Content-Type"]? || "", resp.body) ? nil : url
    rescue e : IO::Error | Socket::Error | OpenSSL::Error
      STDERR.puts "  ! 查 Google Books 失敗：#{e.message}"
      nil
    end

    def self.placeholder?(content_type : String, body : String) : Bool
      return true if body.bytesize < 2_000
      return true if content_type.includes?("png") && body.bytesize < 4_000
      Digest::MD5.hexdigest(body) == PLACEHOLDER_MD5
    end

    # 讀檔案的 isbn，找到書封就把 cover: 寫進 front matter。回傳寫入的網址。
    def self.apply(path : String) : String?
      raw = File.read(path)
      parsed = Frontmatter.split(raw)
      if existing = parsed.data["cover"]?.try(&.as_s?)
        puts "  = #{path} 已有 cover: #{existing}"
        return existing
      end
      isbn = parsed.data["isbn"]?.try(&.raw.to_s)
      raise Error.new("#{path} 沒有 isbn 欄位") if isbn.nil? || isbn.empty?
      url = lookup(isbn)
      unless url
        puts "  ✗ Google Books 沒有 #{isbn} 的書封；請手動在 #{path} 加 cover:（例如博客來的圖片網址）"
        return nil
      end
      updated = raw.sub(/^isbn:[^\n]*/m) { |line| "#{line}\ncover: #{url}" }
      File.write(path, updated)
      puts "  ✓ #{path} cover: #{url}"
      url
    end
  end
end
