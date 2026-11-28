// 用 Edge DevTools Protocol 精确截图：node tool/shot.mjs <opt-json-file>
// opt: { url, out, w, h, full, theme, wait }
import fs from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";

const raw = (process.argv[2] ?? "").replace(/^@/, "");
const content = fs.readFileSync(raw, "utf8").replace(/^\uFEFF/, "");
const opt = JSON.parse(content);

const EDGE = [
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  "C:/Program Files/Microsoft/Edge/Application/msedge.exe",
].find((p) => fs.existsSync(p));

const PORT = 9334;
const userDir = path.join(process.env.TEMP, "edge-shot-profile");

const child = spawn(
  EDGE,
  [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    `--remote-debugging-port=${PORT}`,
    `--user-data-dir=${userDir}`,
    "--no-first-run",
    "--no-default-browser-check",
    "about:blank",
  ],
  { detached: true, stdio: "ignore" }
);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function targetWs() {
  for (let i = 0; i < 80; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/json/list`);
      const list = await res.json();
      const page = list.find((t) => t.type === "page");
      if (page?.webSocketDebuggerUrl) return page.webSocketDebuggerUrl;
    } catch {}
    await sleep(150);
  }
  throw new Error("devtools not ready");
}

const ws = new WebSocket(await targetWs());
await new Promise((r) => ws.addEventListener("open", r, { once: true }));

let id = 0;
const pending = new Map();
const events = [];
ws.addEventListener("message", (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id);
    pending.delete(msg.id);
    msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
  } else if (msg.method) {
    events.push(msg.method);
  }
});

const send = (method, params = {}) =>
  new Promise((resolve, reject) => {
    const mid = ++id;
    pending.set(mid, { resolve, reject });
    ws.send(JSON.stringify({ id: mid, method, params }));
  });

const w = opt.w ?? 1440;
const h = opt.h ?? 900;

await send("Page.enable");
await send("Emulation.setDeviceMetricsOverride", {
  width: w,
  height: h,
  deviceScaleFactor: opt.dsf ?? 1,
  mobile: false,
});
if (opt.theme) {
  await send("Page.navigate", { url: "about:blank" });
  await sleep(120);
  await send("Page.addScriptToEvaluateOnNewDocument", {
    source: `try{localStorage.setItem('xinyu-theme',${JSON.stringify(opt.theme)})}catch(e){}`,
  });
}
await send("Page.navigate", { url: opt.url });
for (let i = 0; i < 120 && !events.includes("Page.loadEventFired"); i++) await sleep(100);
await sleep(opt.wait ?? 900);

if (opt.reveal !== false) {
  await send("Runtime.enable");
  await send("Runtime.evaluate", {
    expression:
      "document.querySelectorAll('.reveal').forEach(function(e){e.classList.add('is-in')});1",
  });
  await sleep(400);
}

let clip;
if (opt.full) {
  const m = await send("Page.getLayoutMetrics");
  const cs = m.cssContentSize ?? m.contentSize;
  clip = { x: 0, y: 0, width: w, height: Math.ceil(cs.height), scale: 1 };
}
const shot = await send("Page.captureScreenshot", {
  format: "png",
  captureBeyondViewport: !!opt.full,
  ...(clip ? { clip } : {}),
});
fs.writeFileSync(opt.out, Buffer.from(shot.data, "base64"));
console.log(JSON.stringify({ out: opt.out, viewport: [w, h], clip: clip ?? null }));

ws.close();
try {
  process.kill(-child.pid);
} catch {
  try { child.kill(); } catch {}
}
process.exit(0);
