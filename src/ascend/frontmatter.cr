require "yaml"

module Ascend
  module Frontmatter
    record Parsed, data : YAML::Any, body : String

    FENCE = /\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\z/m

    # 把 `---` 包起來的 YAML 與正文分開。
    def self.split(raw : String) : Parsed
      raise Error.new("檔案必須以 --- front matter 開頭") unless raw.starts_with?("---")
      m = FENCE.match(raw)
      raise Error.new("front matter 沒有結尾的 ---") unless m
      yaml = m[1].strip
      data = yaml.empty? ? YAML.parse("{}") : YAML.parse(yaml)
      raise Error.new("front matter 必須是 key: value 對應") unless data.as_h?
      Parsed.new(data, m[2])
    rescue e : YAML::ParseException
      raise Error.new("front matter YAML 解析失敗：#{e.message}")
    end
  end
end
