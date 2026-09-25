require "./spec_helper"

describe Ascend::Scaffold do
  it "creates a new book file from the template" do
    dir = File.tempname("ascend-new")
    Dir.mkdir_p(dir)
    File.write("#{dir}/_template.md", "---\ntitle: 標題\nauthor: 作者\ndate: 2026-01-01\ntags: []\n---\n\n## 為什麼讀\n")
    path = Ascend::Scaffold.new_book("我的 書/名", "某人", dir, Time.local(2026, 9, 25))
    path.should eq "#{dir}/2026-09-25-我的-書名.md"
    content = File.read(path)
    content.should contain "title: 我的 書/名"
    content.should contain "author: 某人"
    content.should contain "date: 2026-09-25"
    content.should contain "## 為什麼讀"
    expect_raises(Ascend::Error, /已存在/) { Ascend::Scaffold.new_book("我的 書/名", nil, dir, Time.local(2026, 9, 25)) }
    expect_raises(Ascend::Error, /書名/) { Ascend::Scaffold.new_book("  ", nil, dir) }
  ensure
    FileUtils.rm_rf(dir) if dir
  end
end
