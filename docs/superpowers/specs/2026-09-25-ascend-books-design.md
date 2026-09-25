# Ascend Books — 讀書心得靜態站產生器 設計規格

**日期：** 2026-09-25
**狀態：** 自主模式下擬定（使用者未即時審核，假設項已標示）
**網址：** https://ascend-books.1tron.ai

---

## 目標

- 用 **Crystal** 寫一個小型靜態站產生器 `ascend`，向 Astro 學習專案結構與 DX：
  content collections + frontmatter schema、layouts / components、clean URL 輸出、`public/` 原樣複製、`dist/` 輸出、dev server 熱重建、sitemap / RSS。
- 樣式用 **Tailwind 4 + daisyUI 5**（透過 bun 的 `@tailwindcss/cli` 產生單一 CSS）。
- 產出第一個站：**讀書心得**，部署到 `ascend-books.1tron.ai`。

## 非目標

- 不做 CMS、留言、登入。
- 不做全文搜尋引擎；只做首頁的前端即時篩選（標題／作者／標籤）。
- 不做多語系。
- 不做書封圖片抓取（作者可自行放 `public/covers/`，frontmatter 用 `cover:` 指向）。

## 假設（使用者未確認）

1. 站名顯示為「Ascend Books」＋副標「讀書心得」，可在 `site.yml` 改。
2. 首批內容從 `~/ai/_books` 移植一篇既有心得（靈界修行筆記），並依「修道學習路徑」把三本待讀書列為 `status: wishlist`，文字皆取自使用者自己的筆記。
3. 部署到 **GitHub Pages**（使用者於 2026-09-25 補充）：GitHub Actions 在 push 到 main 時安裝 Crystal + bun、`ascend build`、上傳 `dist/` 到 Pages；`public/CNAME` 寫 `ascend-books.1tron.ai`，DNS 端加 CNAME 指到 `<user>.github.io`。
4. 模板採 ECR（編譯期），dev 模式下模板／原始碼變動時自動重編譯並重啟；內容、CSS、public 變動只需重建。

---

## 專案結構

```
ascend_books/
├── site.yml                  # 站台設定（title, url, author, description, nav）
├── shard.yml                 # Crystal 相依：markd
├── package.json              # bun 相依：tailwindcss, @tailwindcss/cli, daisyui, @tailwindcss/typography
├── src/
│   ├── ascend.cr             # CLI 入口：build / dev / new / check
│   ├── ascend/
│   │   ├── config.cr         # site.yml 讀取
│   │   ├── frontmatter.cr    # 切 frontmatter + YAML
│   │   ├── book.cr           # Book 結構 + schema 驗證（Astro content collections 精神）
│   │   ├── page.cr           # 獨立頁（about）
│   │   ├── collection.cr     # 讀 content/ 目錄、排序、草稿過濾、標籤索引
│   │   ├── markdown.cr       # markd 轉 HTML、字數、摘要
│   │   ├── renderer.cr       # ECR layouts/components/pages
│   │   ├── feeds.cr          # rss.xml / sitemap.xml / robots.txt
│   │   ├── builder.cr        # 組裝 dist/
│   │   ├── css.cr            # 呼叫 bunx @tailwindcss/cli
│   │   ├── server.cr         # dev server（HTTP::Server，clean URL）
│   │   └── watcher.cr        # mtime 輪詢；決定重建 or 重編譯
│   └── styles/site.css       # @import tailwindcss; @plugin daisyui; 自訂主題
├── templates/
│   ├── layouts/base.ecr
│   ├── components/{navbar,footer,book_card,tag_chips,rating,status_badge,meta}.ecr
│   └── pages/{index,book,tags,tag,page,404}.ecr
├── content/
│   ├── books/*.md            # 讀書心得 collection
│   ├── books/_template.md
│   └── pages/about.md
├── public/                   # favicon.svg, robots.txt, covers/
├── spec/                     # Crystal specs
├── .github/workflows/deploy.yml   # GitHub Pages 部署
├── Makefile
└── dist/                     # 輸出（不進 git）
```

## 內容模型（`content/books/<slug>.md`）

```yaml
---
title: 靈界修行筆記         # 必填
author: 隨緣                # 必填
date: 2026-04-05           # 必填，YYYY-MM-DD
tags: [靈修]               # 選填，預設 []
rating: 4                  # 選填 1–5
status: done               # 選填 reading | done | wishlist，預設 done
publisher: 某出版社         # 選填
year: 2020                 # 選填 出版年
isbn: 978...               # 選填
cover: /covers/x.jpg       # 選填
description: 一句話         # 選填；沒給就用正文前 80 字
draft: false               # 選填；true 不輸出
---
正文 Markdown
```

驗證失敗（缺必填、日期格式錯、rating 超範圍、status 不在集合）→ 顯示 `content/books/xxx.md: 錯誤訊息` 並以非 0 結束，模仿 Astro 的 schema 錯誤。

`slug` = 檔名去 `.md`。允許中文檔名（URL 會 percent-encode，但輸出目錄用原字）。

## 路由（Astro 風格 clean URL）

| URL | 來源 |
|---|---|
| `/` | 所有非草稿書，日期新→舊；含即時篩選 |
| `/books/<slug>/` | 單篇心得 |
| `/tags/` | 標籤總覽（數量） |
| `/tags/<tag>/` | 該標籤書單 |
| `/about/` | `content/pages/about.md` |
| `/rss.xml`、`/sitemap.xml`、`/robots.txt`、`/404.html` | 產生器輸出 |
| `/assets/site.css` | Tailwind 輸出 |

## 版面與視覺

- daisyUI 自訂主題 `ascend`（亮）＋ `ascend-dark`（暗，跟隨系統）。紙感暖白底、墨色字、主色靛藍、點綴金。標題 Noto Serif TC，內文 Noto Sans TC。
- 首頁：Hero（站名、副標、統計：本數／標籤數）→ 篩選列 → 書卡格（書名、作者、日期、狀態、評分、摘要、標籤）。
- 單篇：標題區（書名／作者／出版資訊／評分／狀態／標籤／字數）→ `prose` 正文 → 上下篇導覽 → 返回。
- SEO：title/description/canonical/OG/Twitter、JSON-LD `Review`+`Book`。

## CLI

```
ascend build            # 清 dist、驗內容、產 HTML、CSS、feeds、複製 public
ascend dev [--port N]   # build + serve :4321 + 監看
ascend new "書名"        # 由 _template.md 建 content/books/YYYY-MM-DD-書名.md
ascend check            # 只驗內容不輸出
```

## 錯誤處理

- 內容錯誤：集中列出所有檔案的錯誤後一次退出（不是遇到第一個就停）。
- Tailwind 失敗：印出 bun 輸出、退出非 0；dev 模式印錯不中斷。
- dev 模式重編譯失敗：印出編譯錯誤，繼續用舊二進位服務。

## 測試

Crystal spec：frontmatter 切割、Book 驗證（成功／各種失敗）、摘要與字數、slug 與 URL 編碼、collection 排序與草稿過濾、標籤索引、RSS/sitemap 內容、renderer 含關鍵字。

## 部署（GitHub Pages）

- `.github/workflows/deploy.yml`：`on: push (main)` + `workflow_dispatch`。步驟：checkout → `crystal-lang/install-crystal` → `oven-sh/setup-bun` → `shards install` → `bun install --frozen-lockfile` → `crystal build --release src/ascend.cr -o bin/ascend` → `bin/ascend build` → `actions/upload-pages-artifact`（`dist/`）→ `actions/deploy-pages`。
- `public/CNAME` = `ascend-books.1tron.ai`；`public/.nojekyll` 避免 Jekyll 處理。
- 倉庫 Settings → Pages → Source 選 **GitHub Actions**；DNS 加 `ascend-books CNAME <owner>.github.io`。
- 本機 `make deploy` 等同 `git push origin main`（部署由 Actions 完成）。
