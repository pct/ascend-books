module Ascend
  # 透過 bun 的 @tailwindcss/cli 產生 dist/assets/site.css（Tailwind 4 + daisyUI 5）。
  module CSS
    INPUT = "src/styles/site.css"

    def self.build(out_dir : String, minify : Bool = true) : Bool
      output = File.join(out_dir, "assets", "site.css")
      Dir.mkdir_p(File.dirname(output))
      local = "node_modules/.bin/tailwindcss"
      cmd, args = if File.exists?(local)
                    {local, [] of String}
                  else
                    {"bunx", ["@tailwindcss/cli"]}
                  end
      args += ["-i", INPUT, "-o", output]
      args << "--minify" if minify
      log = IO::Memory.new
      status = Process.run(cmd, args, output: log, error: log)
      unless status.success?
        STDERR.puts "  ✗ Tailwind 失敗（#{cmd} #{args.join(" ")}）"
        STDERR.puts log.to_s
      end
      status.success?
    rescue e : IO::Error
      STDERR.puts "  ✗ 找不到 #{cmd}：#{e.message}"
      STDERR.puts "    請先執行 `bun install`（需要 bun：https://bun.sh）"
      false
    end
  end
end
