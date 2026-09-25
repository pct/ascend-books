# Ascend Books — 讀書心得

<https://ascend-books.1tron.ai>

用自己寫的 Crystal 靜態站產生器 `ascend` 產生：Markdown 進、靜態 HTML 出。
樣式 Tailwind 4 + daisyUI 5（透過 bun 的 `@tailwindcss/cli`），部署 GitHub Pages。
專案結構學 Astro：content collection + frontmatter schema、layouts / components、clean URL、`public/` 原樣複製、`dist/` 輸出、dev server 熱重建、sitemap / RSS。

## 需求

- [Crystal](https://crystal-lang.org/install/) 1.10+
- [bun](https://bun.sh)（只用來跑 Tailwind）

## 開始

```bash
make setup        # shards install + bun install
make dev          # 建置 + http://127.0.0.1:4321 + 監看
make build        # 建置到 dist/
make check        # 只驗證內容
make spec         # 跑測試
make new T="書名" A="作者"   # 建 content/books/YYYY-MM-DD-書名.md
```

或直接用 CLI：`shards build` 後 `bin/ascend build|dev|check|new`。

dev 模式：改 `content/`、`public/`、`src/styles/`、`site.yml` 會自動重建並 live reload；
改 `templates/`、`src/*.cr` 會自動重新編譯再重啟。

## 寫一篇

`content/books/<slug>.md`，slug 就是網址（`/books/<slug>/`）：

```yaml
---
title: 書名                 # 必填
author: 作者                # 必填
date: 2026-09-25           # 必填 YYYY-MM-DD
tags: [觀想, 平行世界]      # 選填
status: done               # reading | done | wishlist（預設 done）
rating: 4                  # 選填 1–5
publisher: 楓書坊           # 選填
year: 2024                 # 選填
isbn: 9789863779506        # 選填
cover: https://...         # 選填，書封網址（有 isbn 可用 `ascend cover 檔名` 先問 Google Books）
buy:                       # 選填，購買連結，照寫的順序顯示
  博客來: https://www.books.com.tw/products/0010982012
  momo: https://www.momoshop.com.tw/goods/GoodsDetail.jsp?i_code=...
description: 一句話         # 選填，沒給就取正文前 80 字
draft: true                # 選填，不輸出（dev 模式看得到）
---
正文 Markdown
```

欄位錯了 `ascend build` 會一次列出所有檔案的錯誤再停下來。

獨立頁面（若需要）放 `content/pages/<slug>.md`（例如 `about.md` → `/about/`），只需要 `title`；目前沒有。

## 站台設定

`site.yml`：`title`、`subtitle`、`description`、`url`、`author`、`footer`、`nav`、`og_image`、`head_html`。

### 流量統計

`head_html` 會原樣放進每頁 `<head>`。建議 [Cloudflare Web Analytics](https://www.cloudflare.com/web-analytics/)（免費、無 cookie；1tron.ai 已在 Cloudflare 上，
Dashboard → Analytics & Logs → Web Analytics → 加站台 → 複製 script）：

```yaml
head_html: |
  <script defer src="https://static.cloudflareinsights.com/beacon.min.js" data-cf-beacon='{"token": "xxxx"}'></script>
```

也可以放 GoatCounter、Umami、Plausible 的 script。GitHub Pages 本身沒有流量報表。

## 部署

### GitHub Pages（預設）

1. 建 GitHub repo，`git push origin main`。
2. Settings → Pages → Build and deployment → Source 選 **GitHub Actions**。
3. DNS（Cloudflare）：`ascend-books` CNAME → `<github帳號>.github.io`，先用灰色雲（DNS only）讓 GitHub 簽憑證，之後可開橘雲。
4. Settings → Pages → Custom domain 填 `ascend-books.1tron.ai`，勾 Enforce HTTPS。`public/CNAME` 已經放好。

之後每次 push main，`.github/workflows/deploy.yml` 會跑測試、建站、發佈。

### Cloudflare Pages

Cloudflare 的建置環境沒有 Crystal，所以一樣在 Actions 裡建好 `dist/`，再用 wrangler 直接上傳：

```bash
bunx wrangler login
bunx wrangler pages project create ascend-books --production-branch main
make deploy-cf        # = bin/ascend build && bunx wrangler pages deploy dist --project-name ascend-books
```

要自動化的話，在 repo secrets 放 `CLOUDFLARE_API_TOKEN`、`CLOUDFLARE_ACCOUNT_ID`，
把 `.github/workflows/deploy.yml` 的 deploy job 換成 `cloudflare/wrangler-action`（`command: pages deploy dist --project-name ascend-books`）。
自訂網域在 Pages 專案的 Custom domains 直接加，DNS 同一個帳號會自動設好。

### 其他

- **Netlify / Vercel**：同樣 Actions 產 `dist/` 後用各自 CLI 上傳（`netlify deploy --prod --dir dist`、`vercel deploy --prebuilt`）。
- **自己的機器（nginx）**：`rsync -az --delete dist/ user@host:/srv/http/ascend-books/`，nginx 用 `try_files $uri $uri/ =404`。

## 分潤

購買連結怎麼申請博客來 AP 策略聯盟、momo 點點賺，見 [docs/affiliate.md](docs/affiliate.md)。

## 結構

```
site.yml                 站台設定
src/main.cr              CLI 入口
src/ascend/              config, frontmatter, markdown, book, page, collection,
                         renderer, feeds, css, builder, server, watcher, scaffold, cli
src/styles/site.css      Tailwind + daisyUI 主題（ascend / ascend-dark）
templates/layouts/       base.ecr
templates/components/    navbar, footer, book_card, tag_chips, rating, status_badge
templates/pages/         index, book, tags, tag, page, 404
content/books/           讀書心得（_template.md 是範本）
content/pages/           獨立頁
public/                  favicon.svg, CNAME, .nojekyll（原樣複製）
spec/                    crystal spec
dist/                    輸出（不進 git）
```
