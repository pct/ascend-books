require "./spec_helper"

describe Ascend::Frontmatter do
  it "splits yaml and body" do
    p = Ascend::Frontmatter.split("---\ntitle: A\n---\nbody here\n")
    p.data["title"].as_s.should eq "A"
    p.body.should eq "body here\n"
  end

  it "accepts CRLF" do
    p = Ascend::Frontmatter.split("---\r\ntitle: A\r\n---\r\nbody")
    p.data["title"].as_s.should eq "A"
    p.body.should eq "body"
  end

  it "rejects files without front matter" do
    expect_raises(Ascend::Error, /---/) { Ascend::Frontmatter.split("# no fm\n") }
  end

  it "rejects unterminated front matter" do
    expect_raises(Ascend::Error, /結尾/) { Ascend::Frontmatter.split("---\ntitle: A\n") }
  end

  it "reports yaml syntax errors" do
    expect_raises(Ascend::Error, /YAML/) { Ascend::Frontmatter.split("---\ntitle: [oops\n---\n") }
  end
end
