.PHONY: setup build dev check new spec clean deploy deploy-cf

CR_SRC := $(shell find src templates -type f)

setup:            ## 安裝相依（shards + bun）
	shards install
	bun install

bin/ascend: $(CR_SRC) shard.yml
	shards build

build: bin/ascend ## 建置到 dist/
	bin/ascend build

dev: bin/ascend   ## dev server（http://127.0.0.1:4321）+ 監看
	bin/ascend dev

check: bin/ascend ## 只驗證內容
	bin/ascend check

new: bin/ascend   ## make new T="書名" [A="作者"]
	bin/ascend new "$(T)" $(if $(A),--author "$(A)",)

spec:             ## 跑測試
	crystal spec

clean:
	rm -rf dist bin

deploy:           ## 推到 GitHub，Actions 會部署到 Pages
	git push origin main

deploy-cf: build  ## 直接上傳 dist/ 到 Cloudflare Pages（需先 bunx wrangler login）
	bunx wrangler pages deploy dist --project-name ascend-books
