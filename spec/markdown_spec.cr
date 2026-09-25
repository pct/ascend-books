require "./spec_helper"

describe Ascend::Markdown do
  it "renders html and adds heading ids" do
    r = Ascend::Markdown.render("## 為什麼讀\n\n內容\n\n### 細節\n\n##### 太深\n")
    r.html.should contain %(<h2 id="為什麼讀">為什麼讀</h2>)
    r.toc.map(&.id).should eq ["為什麼讀", "細節"]
    r.toc.first.level.should eq 2
  end

  it "dedupes heading ids" do
    r = Ascend::Markdown.render("## 同名\n\n## 同名\n")
    r.toc.map(&.id).should eq ["同名", "同名-2"]
  end

  it "strips markdown for excerpt" do
    ex = Ascend::Markdown.excerpt("## 標題\n\n- **粗體** 與 [連結](http://x) 和 `code`\n")
    ex.should eq "粗體 與 連結 和 code"
  end

  it "truncates excerpt by characters, not bytes" do
    ex = Ascend::Markdown.excerpt("中" * 100, 80)
    ex.chars.size.should eq 81
    ex.should end_with "…"
  end

  it "counts cjk characters as words" do
    Ascend::Markdown.word_count("你好，世界。 hello").should eq 4 + 5
  end
end
