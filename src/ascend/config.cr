require "yaml"

module Ascend
  struct NavItem
    include YAML::Serializable
    getter label : String
    getter href : String
  end

  # site.yml
  class Config
    include YAML::Serializable

    getter title : String
    getter subtitle : String = ""
    getter description : String = ""
    getter url : String
    getter author : String = ""
    getter lang : String = "zh-Hant"
    getter footer : String = ""
    getter og_image : String? = nil
    # 流量統計等要塞進 <head> 的原始 HTML（例如 Cloudflare Web Analytics 的 <script>）
    getter head_html : String = ""
    getter nav : Array(NavItem) = [] of NavItem

    def self.load(path : String = "site.yml") : Config
      raise Error.new("找不到 #{path}") unless File.exists?(path)
      Config.from_yaml(File.read(path))
    end

    def base_url : String
      url.rstrip('/')
    end

    def absolute(path : String) : String
      path.starts_with?("/") ? base_url + path : "#{base_url}/#{path}"
    end
  end
end
