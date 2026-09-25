require "spec"
require "../src/ascend"

def sample_book_md(**overrides)
  fields = {
    "title"  => "The Pragmatic Programmer",
    "author" => "David Thomas, Andrew Hunt",
    "date"   => "2026-03-15",
    "tags"   => "[programming, career]",
    "status" => "done",
    "rating" => "5",
  }
  overrides.each { |k, v| fields[k.to_s] = v.to_s }
  fm = fields.compact_map { |k, v| v.empty? ? nil : "#{k}: #{v}" }.join("\n")
  "---\n#{fm}\n---\n\n## 為什麼讀\n\n這本書改變了我對軟體工藝的看法。\n\n- 第一點\n- 第二點\n"
end

def test_config
  Ascend::Config.from_yaml(<<-YAML)
    title: 測試站
    subtitle: 讀書心得
    description: 測試用
    url: https://example.com/
    author: tester
    nav:
      - { label: 書架, href: / }
    YAML
end
