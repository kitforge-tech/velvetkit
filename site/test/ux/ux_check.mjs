// UX checks with real input (mouse, keyboard, clipboard) in headless Chrome:
// the focus ring and copy feedback. Run with bin/ux-check against a running
// site; each check is about what a person sees, not what the markup says.
//   bin/ux-check                      (site on localhost:3000)
//   UX_BASE_URL=http://localhost:3311 bin/ux-check
const [, , wsUrl] = process.argv;
const BASE = process.env.UX_BASE_URL || "http://localhost:3000";
setTimeout(() => { console.log("TIMED OUT"); process.exit(1); }, 90000);

const ws = new WebSocket(wsUrl);
let id = 0;
const pending = new Map();
ws.onmessage = (m) => { const msg = JSON.parse(m.data); pending.get(msg.id)?.(msg); };
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const run = async (expr) => {
  const res = await send("Runtime.evaluate", { expression: expr, awaitPromise: true, returnByValue: true, userGesture: true });
  if (res.result.exceptionDetails) throw new Error(res.result.exceptionDetails.text + " in: " + expr.slice(0, 80));
  return res.result.result.value;
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const results = [];
const check = (name, ok, detail = "") => { results.push(ok); console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? "  — " + detail : ""}`); };

const center = (sel) => run(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; const r = e.getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; })()`);
const mouse = async (type, [x, y]) => send("Input.dispatchMouseEvent", { type, x, y, button: "left", clickCount: 1 });
const click = async (sel) => { const p = await center(sel); if (!p) throw new Error("not found " + sel); await send("Input.dispatchMouseEvent", { type: "mouseMoved", x: p[0], y: p[1] }); await mouse("mousePressed", p); await mouse("mouseReleased", p); };
// Spread of the outermost ring shadow, in px (0 when none).
const spread = (sel) => run(`(() => { const m = [...getComputedStyle(document.querySelector(${JSON.stringify(sel)}) || document.activeElement).boxShadow.matchAll(/0px 0px 0px ([\\d.]+)px/g)].map(x => +x[1]); return m.length ? Math.max(...m) : 0; })()`);

ws.onopen = async () => {
  try {
    await send("Browser.grantPermissions", { origin: BASE, permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"] });
    await send("Emulation.setDeviceMetricsOverride", { width: 1400, height: 820, deviceScaleFactor: 1, mobile: false });
    await send("Page.navigate", { url: `${BASE}/docs` });
    await sleep(2500);

    // 1. The ring animates in on click.
    const header = '[data-focus-scope="header"] a[href="/docs/components"]';
    const p = await center(header);
    await mouse("mousePressed", p);
    const early = await spread(header);
    await sleep(300);
    const settled = await spread(header);
    check("ring animates in on click", early < settled && settled >= 3, `${early}px right after press, ${settled}px at 300ms`);
    await mouse("mouseReleased", p);
    await sleep(2000);

    // 2. The ring is on the same link after the visit, already whole.
    const carried = await run(`(() => { const a = document.activeElement; return { url: location.pathname, text: a.textContent.trim() }; })()`);
    const after = await spread(header);
    check("ring carried to the new page", carried.url === "/docs/components" && carried.text === "Components" && after >= 3, `${carried.text} on ${carried.url}, ${after}px`);

    // 3. A sidebar ring isn't clipped by the scroll area.
    const sidebarLink = '[data-focus-scope="sidebar"] a[href="/docs/components/button"]';
    await click(sidebarLink);
    await sleep(2000);
    const room = await run(`(() => { const box = document.querySelector('[data-focus-scope="sidebar"]'); const s = getComputedStyle(box); const b = box.getBoundingClientRect(); const a = document.activeElement.getBoundingClientRect();
      return { left: Math.round(a.left - (b.left + parseFloat(s.paddingLeft) - 6)), right: Math.round(b.right - a.right), ringOn: document.activeElement.textContent.trim() }; })()`);
    check("sidebar ring has room on both sides", room.left >= 3 && room.right >= 3, `${room.left}px left, ${room.right}px right of '${room.ringOn}'`);

    // 4. Copy a code block: clipboard, icon, label, announcement, reset.
    await send("Page.navigate", { url: `${BASE}/docs/components/dialog` });
    await sleep(2500);
    const block = '#install [data-controller="clipboard"]';
    await click(`${block} button`);
    await sleep(250);
    const copied = await run(`(async () => { const b = document.querySelector('${block}');
      const shown = (sel) => { const e = b.querySelector(sel); return e && !e.hasAttribute('hidden') && getComputedStyle(e).display !== 'none'; };
      return { clip: await navigator.clipboard.readText(), tick: shown('[data-clipboard-target=done]'), copyIcon: shown('[data-clipboard-target=idle]'),
               label: shown('[data-clipboard-target=label]') && b.querySelector('[data-clipboard-target=label]').textContent,
               status: b.querySelector('[data-clipboard-target=status]').textContent,
               buttonVisible: getComputedStyle(b.querySelector('button')).opacity }; })()`);
    check("copy puts the command on the clipboard", copied.clip === "bin/rails generate velvetkit:add dialog", JSON.stringify(copied.clip));
    check("copy swaps the icon for a tick", copied.tick && !copied.copyIcon);
    check("copy shows a 'Copied' label", copied.label === "Copied", String(copied.label));
    check("copy is announced to screen readers", copied.status === "Copied");
    check("button stays visible while showing the result", copied.buttonVisible === "1", `opacity ${copied.buttonVisible}`);
    await sleep(2000);
    const reset = await run(`(() => { const b = document.querySelector('${block}'); return { tick: !b.querySelector('[data-clipboard-target=done]').hasAttribute('hidden'), label: !b.querySelector('[data-clipboard-target=label]').hasAttribute('hidden') }; })()`);
    check("copy feedback clears after a moment", !reset.tick && !reset.label);

    // 5. Ask AI > Copy as Markdown, with the menu closing.
    await click('[data-controller="clipboard"] [data-ui--menu-target="trigger"], [data-controller="clipboard"] button[aria-haspopup]');
    await sleep(300);
    await run(`(() => { const item = [...document.querySelectorAll('[role=menuitem]')].find(i => i.textContent.includes('Copy as Markdown')); item.setAttribute('data-test-copy', ''); })()`);
    await click("[data-test-copy]");
    await sleep(300);
    const md = await run(`(async () => { const l = [...document.querySelectorAll('[data-clipboard-target=label]')].find(e => !e.hasAttribute('hidden')); return { clip: (await navigator.clipboard.readText()).slice(0, 30), label: l && l.textContent }; })()`);
    check("Ask AI copies the Markdown", md.clip.startsWith("# VelvetKit"), JSON.stringify(md.clip));
    check("Ask AI says it copied, beside the menu", md.label === "Markdown copied", String(md.label));

    // 6. If the clipboard is refused, the text is selected and the label says how to copy.
    await run(`navigator.clipboard.writeText = () => Promise.reject(new Error('denied'))`);
    await click(`${block} button`);
    await sleep(250);
    const refused = await run(`(() => { const b = document.querySelector('${block}'); return { label: b.querySelector('[data-clipboard-target=label]').textContent, selected: String(window.getSelection()) }; })()`);
    check("refused clipboard selects the text and explains", refused.selected === "bin/rails generate velvetkit:add dialog" && refused.label.includes("copy"), refused.label);
    // 7. Search: ⌘K and / open it, typing ranks title matches first, Enter goes.
    await send("Page.navigate", { url: `${BASE}/docs` });
    await sleep(2500);
    const key = async (key, code, modifiers = 0, vk = 0) => {
    await send("Input.dispatchKeyEvent", { type: "keyDown", key, code, modifiers, windowsVirtualKeyCode: vk });
    await send("Input.dispatchKeyEvent", { type: "keyUp", key, code, modifiers, windowsVirtualKeyCode: vk });
    };
    const searchState = () => run(`(() => { const d = document.querySelector('dialog[aria-label="Search the docs"]'); const i = d.querySelector('input');
    const byOrder = (a, b) => (a.style.order || 0) - (b.style.order || 0);
    const vis = [...d.querySelectorAll('[data-search-target=group]:not([hidden])')].sort(byOrder)
      .flatMap(g => [...g.querySelectorAll('[role=option]:not([hidden])')].sort(byOrder));
    return { open: d.open, focused: document.activeElement === i, first: vis[0]?.querySelector('span')?.textContent, count: vis.length,
           selected: d.querySelector('[role=option][aria-selected=true] span')?.textContent, empty: !d.querySelector('[data-search-target=empty]').hidden }; })()`);
    await key("k", "KeyK", 4, 75);
    await sleep(400);
    let st = await searchState();
    check("⌘K opens search with the cursor in it", st.open && st.focused);
    await send("Input.insertText", { text: "date" });
    await sleep(150);
    st = await searchState();
    check("typing ranks the matching component first", st.first === "Date picker" && st.selected === "Date picker", `${st.first}, ${st.count} shown`);
    await key("Enter", "Enter", 0, 13);
    // Wait for the visit rather than a fixed time: a cold page renders slowly in development.
    for (let i = 0; i < 40 && (await run("location.pathname")) !== "/docs/components/date_picker"; i++) await sleep(200);
    check("Enter opens the result", (await run("location.pathname")) === "/docs/components/date_picker");
    await sleep(800);
    await key("k", "KeyK", 4, 75);
    await sleep(400);
    await run(`document.querySelector('dialog[aria-label="Search the docs"] input').value = ""`);
    await send("Input.insertText", { text: "select" });
    await sleep(150);
    st = await searchState();
    check("a title starting with the query ranks first", st.first === "Select", String(st.first));
    await key("ArrowDown", "ArrowDown", 0, 40);
    st = await searchState();
    check("↓ moves to the next result", st.selected && st.selected !== "Select", String(st.selected));
    await run(`document.querySelector('dialog[aria-label="Search the docs"] input').value = ""`);
    await send("Input.insertText", { text: "se" });
    await sleep(150);
    st = await searchState();
    check("a strong component match outranks a weak guide match", st.first === "Select" && st.selected === "Select", `${st.first} first, ${st.selected} selected`);
    await key("Escape", "Escape", 0, 27);
    await sleep(400);
    await key("/", "Slash", 0, 191);
    await sleep(400);
    st = await searchState();
    check("/ opens search too", st.open && st.focused);
    await send("Input.insertText", { text: "zzzzq" });
    await sleep(150);
    st = await searchState();
    check("no matches says so", st.empty && st.count === 0);
    await key("Escape", "Escape", 0, 27);
    await sleep(400);
    st = await searchState();
    check("Escape closes search", !st.open);
  } catch (error) {
    console.log("ERROR", error.message);
    results.push(false);
  }
  console.log(`\n${results.filter(Boolean).length}/${results.length} passed`);
  ws.close();
  process.exit(results.every(Boolean) ? 0 : 1);
};
