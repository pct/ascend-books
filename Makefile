# Ascend Books — 直接 `make` 看說明；所有指令都是包 bin/ascend
.DEFAULT_GOAL := 說明
.PHONY: 說明 安裝 編譯 建置 預覽 檢查 新書 書封 測試 部署 狀態 清除 \
        help setup build dev check new cover spec deploy status clean

SRC := $(shell find src templates -type f) shard.yml

說明:            ## 列出所有指令
	@echo "Ascend Books（bin/ascend）"
	@echo
	@echo "  make 安裝                 第一次：shards install + bun install"
	@echo "  make 建置                 產生整個站到 dist/"
	@echo "  make 預覽                 本機看：http://127.0.0.1:4321（改檔自動重建）"
	@echo "  make 檢查                 只驗證 content/ 的 front matter，不輸出"
	@echo "  make 新書 T=\"書名\" [A=\"作者\"]   建 content/books/今天-書名.md"
	@echo "  make 書封 F=content/books/xxx.md   依 isbn 到 Google Books 找書封"
	@echo "  make 測試                 crystal spec"
	@echo "  make 部署                 git push main → GitHub Actions 部署到 ascend.1tron.ai"
	@echo "  make 狀態                 看最近一次部署跑得怎樣"
	@echo "  make 清除                 刪 dist/ 與 bin/"
	@echo
	@echo "  英文別名：setup build dev check new cover spec deploy status clean"

安裝:
	shards install
	bun install

bin/ascend: $(SRC)
	shards build

編譯: bin/ascend

建置: bin/ascend
	bin/ascend build

預覽: bin/ascend
	bin/ascend dev

檢查: bin/ascend
	bin/ascend check

新書: bin/ascend
	@test -n "$(T)" || { echo "用法：make 新書 T=\"書名\" [A=\"作者\"]"; exit 2; }
	bin/ascend new "$(T)" $(if $(A),--author "$(A)",)

書封: bin/ascend
	@test -n "$(F)" || { echo "用法：make 書封 F=content/books/xxx.md"; exit 2; }
	bin/ascend cover "$(F)"

測試:
	crystal spec

部署: 檢查
	git push origin main
	@echo "已推上 GitHub，Actions 會建置並部署；看進度：make 狀態"

狀態:
	gh run list --limit 3

清除:
	rm -rf dist bin

# ── 英文別名 ───────────────────────────────
help: 說明
setup: 安裝
build: 建置
dev: 預覽
check: 檢查
new: 新書
cover: 書封
spec: 測試
deploy: 部署
status: 狀態
clean: 清除
