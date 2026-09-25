module Ascend
  # 輪詢 mtime。內容／public／CSS 變動 → :rebuild；模板／原始碼變動 → :recompile。
  class Watcher
    REBUILD_GLOBS   = ["content/**/*", "public/**/*", "src/styles/**/*", "site.yml"]
    RECOMPILE_GLOBS = ["templates/**/*", "src/**/*.cr", "shard.yml"]

    @rebuild : Hash(String, Int64)
    @recompile : Hash(String, Int64)

    def initialize
      @rebuild = snapshot(REBUILD_GLOBS)
      @recompile = snapshot(RECOMPILE_GLOBS)
    end

    def poll : Symbol?
      r = snapshot(RECOMPILE_GLOBS)
      if r != @recompile
        @recompile = r
        return :recompile
      end
      b = snapshot(REBUILD_GLOBS)
      if b != @rebuild
        @rebuild = b
        return :rebuild
      end
      nil
    end

    private def snapshot(globs : Array(String)) : Hash(String, Int64)
      h = {} of String => Int64
      Dir.glob(globs, match: File::MatchOptions::DotFiles).each do |f|
        next unless File.file?(f)
        h[f] = File.info(f).modification_time.to_unix_ms
      end
      h
    end
  end
end
