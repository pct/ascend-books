# Ascend Books — `make` 或 `make help` 看中文說明；指令全是包 bin/ascend
.DEFAULT_GOAL := help
.PHONY: help setup build dev check new cover spec deploy deploy-cf status clean

SRC := $(shell find src templates -type f) shard.yml

help:            ## 說明
	@echo "Ascend Books（bin/ascend）"
	@echo
	@echo "  make setup                     第一次：shards install + bun install"
	@echo "  make build                     產生整個站到 dist/"
	@echo "  make dev                       本機預覽 http://127.0.0.1:4321（改檔自動重建）"
	@echo "  make check                     只驗證 content/ 的 front matter，不輸出"
	@echo "  make new T=\"書名\" [A=\"作者\"]    建 content/books/今天-書名.md"
	@echo "  make cover F=content/books/xxx.md   依 isbn 到 Google Books 找書封"
	@echo "  make spec                      跑測試（crystal spec）"
	@echo "  make deploy                    先 check，再 git push main → Actions 部署到 ascend.1tron.ai"
	@echo "  make deploy-cf                 build 後直接上傳 dist/ 到 Cloudflare Pages（要先 bunx wrangler login）"
	@echo "  make status                    看最近幾次部署狀態"
	@echo "  make clean                     刪 dist/ 與 bin/"

setup:
	shards install
	bun install

bin/ascend: $(SRC)
	shards build

build: bin/ascend
	bin/ascend build

dev: bin/ascend
	bin/ascend dev

check: bin/ascend
	bin/ascend check

new: bin/ascend
	@test -n "$(T)" || { echo "用法：make new T=\"書名\" [A=\"作者\"]"; exit 2; }
	bin/ascend new "$(T)" $(if $(A),--author "$(A)",)

cover: bin/ascend
	@test -n "$(F)" || { echo "用法：make cover F=content/books/xxx.md"; exit 2; }
	bin/ascend cover "$(F)"

spec:
	crystal spec

deploy: check
	git push origin main
	@echo "已推上 GitHub，Actions 會建置並部署；看進度：make status"

deploy-cf: build
	bunx wrangler pages deploy dist --project-name ascend-books

status:
	gh run list --limit 3

clean:
	rm -rf dist bin
