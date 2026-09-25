require "http/server"
require "mime"
require "uri"

module Ascend
  # dev server：clean URL、404 頁、live reload（輪詢 /__ascend/version）。
  class Server
    LIVE_RELOAD = <<-JS
      <script>(()=>{let v=null;setInterval(async()=>{try{const r=await fetch('/__ascend/version',{cache:'no-store'});const t=await r.text();if(v!==null&&t!==v)location.reload();v=t}catch(e){}},800)})()</script>
      JS

    property version : Int32 = 0
    getter port : Int32
    @server : HTTP::Server?

    def initialize(@root : String, @port : Int32)
    end

    def start : Nil
      server = HTTP::Server.new { |ctx| handle(ctx) }
      @server = server
      address = nil
      3.times do |i|
        begin
          address = server.bind_tcp("127.0.0.1", port)
          break
        rescue e : Socket::BindError
          raise e if i == 2
          sleep 0.3.seconds
        end
      end
      puts "  ▶ dev server: http://#{address}"
      spawn { server.listen }
    end

    def close : Nil
      @server.try(&.close)
    end

    def bump : Nil
      @version += 1
    end

    private def handle(ctx : HTTP::Server::Context)
      path = URI.decode(ctx.request.path)
      if path == "/__ascend/version"
        ctx.response.content_type = "text/plain"
        ctx.response.headers["Cache-Control"] = "no-store"
        ctx.response.print version
        return
      end
      if path.includes?("..")
        ctx.response.status = :bad_request
        return
      end

      file = resolve(path)
      unless file
        ctx.response.status = :not_found
        nf = File.join(@root, "404.html")
        if File.file?(nf)
          send_html(ctx, File.read(nf))
        else
          ctx.response.print "404"
        end
        return
      end

      if file.ends_with?(".html")
        send_html(ctx, File.read(file))
      else
        ctx.response.content_type = MIME.from_filename?(file) || "application/octet-stream"
        ctx.response.headers["Cache-Control"] = "no-store"
        File.open(file) { |f| IO.copy(f, ctx.response) }
      end
    end

    private def send_html(ctx, html : String)
      ctx.response.content_type = "text/html; charset=utf-8"
      ctx.response.headers["Cache-Control"] = "no-store"
      injected = html.includes?("</body>") ? html.sub("</body>", LIVE_RELOAD + "</body>") : html + LIVE_RELOAD
      ctx.response.print injected
    end

    private def resolve(path : String) : String?
      base = File.join(@root, path)
      candidates = [] of String
      if path.ends_with?("/")
        candidates << File.join(base, "index.html")
      else
        candidates << base
        candidates << File.join(base, "index.html")
        candidates << "#{base}.html"
      end
      candidates.find { |c| File.file?(c) }
    end
  end
end
