module Ascend
  class Error < Exception; end

  # 單一內容檔的錯誤（缺欄位、格式錯）。
  class ContentError < Error
    getter path : String

    def initialize(@path : String, message : String)
      super("#{@path}: #{message}")
    end
  end

  # 一次收集全部內容錯誤，仿 Astro content collections 一次列完再退出。
  class ContentErrors < Error
    getter errors : Array(ContentError)

    def initialize(@errors : Array(ContentError))
      super("#{@errors.size} 個內容錯誤")
    end
  end
end
