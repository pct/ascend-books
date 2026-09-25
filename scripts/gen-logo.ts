// 用 OpenAI 圖像模型畫站 logo，存到 public/logo.png（並產 favicon 用的 512 版本）。
// 用法：OPENAI_API_KEY=sk-... bun scripts/gen-logo.ts [--model gpt-image-2.5] [--out public/logo.png]
// 沒有 key 就不會動任何檔案。
const args = new Map<string, string>();
for (let i = 2; i < Bun.argv.length; i += 2) args.set(Bun.argv[i].replace(/^--/, ""), Bun.argv[i + 1] ?? "");

const key = process.env.OPENAI_API_KEY;
if (!key) {
  console.error("缺少 OPENAI_API_KEY，例如：OPENAI_API_KEY=sk-... bun scripts/gen-logo.ts");
  process.exit(2);
}
const preferred = args.get("model") ?? "gpt-image-2.5";
const out = args.get("out") ?? "public/logo.png";

const prompt = args.get("prompt") ?? `
A square logo mark for "Ascend Books", a Taoist-flavored reading-notes site.
Subject: a xiuxian (修仙) ascension symbol — a single stylized crane (仙鶴) rising straight upward, wings folded back like an arrow, passing through three stacked auspicious cloud swirls (祥雲) beneath it.
Rendered as a single-color cinnabar red (#B5382E) seal-stamp impression on off-white paper (#F7F6F2): flat, bold, geometric, symmetrical, slightly rough ink-bleed stamp edges, thin square seal border.
Absolutely NO text, NO letters, NO Chinese characters, NO numbers. Centered, fills about 70% of the canvas.
`.trim();

// 找可用模型：優先使用者指定，找不到就退到其他 gpt-image 模型。
async function pickModel(): Promise<string> {
  const res = await fetch("https://api.openai.com/v1/models", { headers: { Authorization: `Bearer ${key}` } });
  if (!res.ok) throw new Error(`/v1/models ${res.status}: ${await res.text()}`);
  const ids: string[] = (await res.json()).data.map((m: any) => m.id);
  if (ids.includes(preferred)) return preferred;
  const fallbacks = ids.filter((id) => id.startsWith("gpt-image")).sort().reverse();
  if (fallbacks.length === 0) throw new Error(`帳號沒有任何 gpt-image 模型（找不到 ${preferred}）`);
  console.warn(`找不到 ${preferred}，改用 ${fallbacks[0]}`);
  return fallbacks[0];
}

const model = await pickModel();
console.log(`模型：${model}\n輸出：${out}`);

const res = await fetch("https://api.openai.com/v1/images/generations", {
  method: "POST",
  headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
  body: JSON.stringify({ model, prompt, size: "1024x1024", n: 1, quality: args.get("quality") ?? "high", output_format: "png", background: "opaque" }),
});
if (!res.ok) {
  console.error(`images/generations ${res.status}: ${await res.text()}`);
  process.exit(1);
}
const json = await res.json();
const b64 = json.data?.[0]?.b64_json;
if (!b64) {
  console.error("回應裡沒有 b64_json：", JSON.stringify(json).slice(0, 500));
  process.exit(1);
}
await Bun.write(out, Buffer.from(b64, "base64"));
console.log(`✓ 已寫入 ${out}（${(Buffer.from(b64, "base64").length / 1024).toFixed(0)} KB）`);
console.log("接著：用 sips 縮成 favicon 與 og：");
console.log(`  sips -Z 512 ${out} --out public/icon-512.png && sips -Z 192 ${out} --out public/icon-192.png`);
