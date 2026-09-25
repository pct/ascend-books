require "http/client"
require "digest/md5"

module Ascend
  # 依 ISBN 到 Google Books 找書封。
  # 1. 先試 ISBN 直接對應的 content 端點；
  # 2. 沒圖就抓 books?vid=ISBN 那頁，把裡面列到的每個版本（volume id，含電子書）都試一遍；
  # 都沒有才回 nil，讓使用者手動填別站的網址。
  module Cover
    BY_ISBN = "https://books.google.com/books/content?vid=ISBN%s&printsec=frontcover&img=1&zoom=1"
    BY_ID   = "https://books.google.com/books/content?id=%s&printsec=frontcover&img=1&zoom=%d"
    VID_PAGE = "https://books.google.com/books?vid=ISBN%s"
    # Google 對「有這本書但沒書封」回的是固定的灰底條紋 JPEG（2026-09 量到 10794 bytes）。
    PLACEHOLDER_MD5 = "d7c21c65fc861fc5128753e9e091b23c"
    UA = "Mozilla/5.0 (ascend static site generator)"

    def self.google_url(isbn : String) : String
      BY_ISBN % clean(isbn)
    end

    def self.clean(isbn : String) : String
      isbn.gsub(/[^0-9Xx]/, "")
    end

    def self.lookup(isbn : String) : String?
      url = google_url(isbn)
      return url if real_image?(url)
      volume_ids(isbn).each do |id|
        # zoom=3 最大（約 575px 寬），再退到 2、1
        [3, 2, 1].each do |zoom|
          candidate = BY_ID % {id, zoom}
          return candidate if real_image?(candidate)
        end
      end
      nil
    rescue e : IO::Error | Socket::Error | OpenSSL::Error
      STDERR.puts "  ! 查 Google Books 失敗：#{e.message}"
      nil
    end

    # books?vid=ISBN 頁面裡出現的 volume id（依出現順序、去重）。
    def self.volume_ids(isbn : String) : Array(String)
      resp = HTTP::Client.get(VID_PAGE % clean(isbn), headers: HTTP::Headers{"User-Agent" => UA})
      # Google 會 302 到 books.google.com.tw 之類的地區網域
      3.times do
        break unless resp.status.redirection?
        location = resp.headers["Location"]? || break
        resp = HTTP::Client.get(location, headers: HTTP::Headers{"User-Agent" => UA})
      end
      return [] of String unless resp.status.success?
      resp.body.scan(/books\?id=([A-Za-z0-9_-]{8,})/).map(&.[1]).uniq
    end

    private def self.real_image?(url : String) : Bool
      resp = HTTP::Client.get(url)
      return false unless resp.status.success?
      !placeholder?(resp.headers["Content-Type"]? || "", resp.body)
    end

    # 沒書封時 Google 仍回 200：查無 ISBN／無封面版本回小 PNG，有書沒封面回固定 JPEG 佔位圖。
    def self.placeholder?(content_type : String, body : String) : Bool
      return true if body.bytesize < 2_000
      return true if content_type.includes?("png")
      Digest::MD5.hexdigest(body) == PLACEHOLDER_MD5
    end

    # 讀檔案的 isbn，找到書封就把 cover: 寫進 front matter（--force 會覆蓋既有的）。回傳網址。
    def self.apply(path : String, force : Bool = false) : String?
      raise Error.new("找不到 #{path}") unless File.file?(path)
      raw = File.read(path)
      parsed = Frontmatter.split(raw)
      existing = parsed.data["cover"]?.try(&.as_s?)
      if existing && !force
        puts "  = #{path} 已有 cover: #{existing}（要換用 --force）"
        return existing
      end
      isbn = parsed.data["isbn"]?.try(&.raw.to_s)
      raise Error.new("#{path} 沒有 isbn 欄位") if isbn.nil? || isbn.empty?
      url = lookup(isbn)
      unless url
        puts "  ✗ Google Books 沒有 #{isbn} 的書封；請手動在 #{path} 加 cover:（例如博客來的圖片網址）"
        return nil
      end
      updated = if existing
                  raw.sub(/^cover:[^\n]*/m, "cover: #{url}")
                else
                  raw.sub(/^isbn:[^\n]*/m) { |line| "#{line}\ncover: #{url}" }
                end
      File.write(path, updated)
      puts "  ✓ #{path} cover: #{url}"
      url
    end
  end
end
