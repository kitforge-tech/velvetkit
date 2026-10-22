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
const key = async (key, code, modifiers = 0, vk = 0) => {
  await send("Input.dispatchKeyEvent", { type: "keyDown", key, code, modifiers, windowsVirtualKeyCode: vk });
  await send("Input.dispatchKeyEvent", { type: "keyUp", key, code, modifiers, windowsVirtualKeyCode: vk });
};
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

    // 3. Sidebar links carry no ring: a click leaves just the current-page
    //    style, and Tab marks the link with a background instead.
    const sidebarLink = '[data-focus-scope="sidebar"] a[href="/docs/components/button"]';
    await click(sidebarLink);
    await sleep(2000);
    const clicked = await run(`(() => { const a = document.activeElement; return { text: a.textContent.trim(), shadow: getComputedStyle(a).boxShadow, outline: getComputedStyle(a).outlineStyle }; })()`);
    check("a clicked sidebar link has no ring", clicked.shadow === "none" && clicked.outline === "none", `${clicked.text}: ${clicked.shadow}`);
    await key("Tab", "Tab", 0, 9);
    await sleep(300);
    const tabbed = await run(`(() => { const a = document.activeElement; return { text: a.textContent.trim(), shadow: getComputedStyle(a).boxShadow, bg: getComputedStyle(a).backgroundColor }; })()`);
    check("Tab marks the next sidebar link without a ring", tabbed.shadow === "none" && tabbed.bg !== "rgba(0, 0, 0, 0)", `${tabbed.text}: ${tabbed.bg}`);

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
    check("copy shows a 'Copied' tooltip", copied.label === "Copied", String(copied.label));
    // The tooltip sits above the button, solid, not over the code; the button
    // lines up with the first line of code.
    const geometry = await run(`(() => { const b = document.querySelector('${block}'); const tip = b.querySelector('[role=tooltip]').getBoundingClientRect();
      const btn = b.querySelector('button').getBoundingClientRect(); const code = b.querySelector('pre').getBoundingClientRect();
      const lineHeight = parseFloat(getComputedStyle(b.querySelector('pre')).lineHeight); const firstLine = code.top + parseFloat(getComputedStyle(b.querySelector('pre')).paddingTop) + lineHeight / 2;
      return { above: Math.round(btn.top - tip.bottom), centred: Math.abs((tip.left + tip.right) / 2 - (btn.left + btn.right) / 2) < 2,
               solid: getComputedStyle(b.querySelector('[role=tooltip]')).backgroundColor, offFromLine: Math.round(Math.abs((btn.top + btn.bottom) / 2 - firstLine)) }; })()`);
    check("tooltip sits just above the button, centred", geometry.above >= 4 && geometry.above <= 12 && geometry.centred, `${geometry.above}px above`);
    check("tooltip is solid", !geometry.solid.includes("/ 0") && !geometry.solid.endsWith(", 0)") && geometry.solid !== "rgba(0, 0, 0, 0)", geometry.solid);
    check("copy button lines up with the first line of code", geometry.offFromLine <= 2, `${geometry.offFromLine}px off`);
    check("copy is announced to screen readers", copied.status === "Copied");
    check("button stays visible while showing the result", copied.buttonVisible === "1", `opacity ${copied.buttonVisible}`);
    await sleep(2000);
    const reset = await run(`(() => { const b = document.querySelector('${block}'); return { tick: !b.querySelector('[data-clipboard-target=done]').hasAttribute('hidden'), label: !b.querySelector('[data-clipboard-target=label]').hasAttribute('hidden') }; })()`);
    check("copy feedback clears after a moment", !reset.tick && !reset.label);

    // 5. Ask AI > Copy as Markdown: the item itself shows the tick and "Copied".
    await click('[data-controller="clipboard"] [data-ui--menu-target="trigger"], [data-controller="clipboard"] button[aria-haspopup]');
    await sleep(300);
    await run(`(() => { const item = [...document.querySelectorAll('[role=menuitem]')].find(i => i.textContent.includes('Copy as Markdown')); item.setAttribute('data-test-copy', ''); })()`);
    await click("[data-test-copy]");
    await sleep(300);
    const md = await run(`(async () => { const item = document.querySelector('[data-test-copy]');
      const shown = (sel) => { const e = item.querySelector(sel); return e && !e.hasAttribute('hidden'); };
      return { clip: (await navigator.clipboard.readText()).slice(0, 30), text: item.innerText.trim(), tick: shown('[data-clipboard-target=done]'),
               icon: shown('[data-clipboard-target=idle]'), menuOpen: getComputedStyle(item).display !== 'none' && item.offsetParent !== null }; })()`);
    check("Ask AI copies the Markdown", md.clip.startsWith("# VelvetKit"), JSON.stringify(md.clip));
    check("the item shows a tick and 'Copied' in place of the copy icon", md.tick && !md.icon && md.text === "Copied" && md.menuOpen, `'${md.text}'`);
    await sleep(2000);
    check("the item goes back to 'Copy as Markdown'", (await run(`document.querySelector('[data-test-copy]').innerText.trim()`)) === "Copy as Markdown");

    // 6. If the clipboard is refused, the text is selected and the label says how to copy.
    await run(`navigator.clipboard.writeText = () => Promise.reject(new Error('denied'))`);
    await click(`${block} button`);
    await sleep(250);
    const refused = await run(`(() => { const b = document.querySelector('${block}'); return { label: b.querySelector('[data-clipboard-target=label]').textContent, selected: String(window.getSelection()) }; })()`);
    check("refused clipboard selects the text and explains", refused.selected === "bin/rails generate velvetkit:add dialog" && refused.label.includes("copy"), refused.label);
    // 7. Search: ⌘K and / open it, typing ranks title matches first, Enter goes.
    await send("Page.navigate", { url: `${BASE}/docs` });
    await sleep(2500);
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

    // 8. The hero rail: arrows scroll a card at a time and grey out at the ends;
    //    the focused track scrolls with ← →; the fade only shows where there's more.
    await send("Page.navigate", { url: `${BASE}/` });
    await sleep(2500);
    const rail = () => run(`(() => { const t = document.querySelector('[data-rail-target=track]');
      return { left: Math.round(t.scrollLeft), prev: document.querySelector('[data-rail-target=previous]').disabled,
               next: document.querySelector('[data-rail-target=next]').disabled, atStart: t.hasAttribute('data-at-start'),
               mask: getComputedStyle(t).maskImage || getComputedStyle(t).webkitMaskImage,
               card: Math.round(t.firstElementChild.getBoundingClientRect().width) }; })()`);
    let r = await rail();
    check("rail starts with ‹ disabled and no left fade", r.left === 0 && r.prev && !r.next && r.atStart && !r.mask.startsWith("linear-gradient(to right, rgba(0, 0, 0, 0)"), r.mask.slice(0, 50));
    await click('[data-rail-target=next]');
    await sleep(900);
    const afterNext = await rail();
    check("› scrolls on by about a card", Math.abs(afterNext.left - (afterNext.card + 20)) <= 24 && !afterNext.prev, `${afterNext.left}px (card ${afterNext.card}px)`);
    await click('[data-rail-target=previous]');
    await sleep(900);
    check("‹ scrolls back", (await rail()).left === 0);
    await run(`document.querySelector('[data-rail-target=track]').focus()`);
    await key("ArrowRight", "ArrowRight", 0, 39);
    await sleep(500);
    check("the focused rail scrolls with →", (await rail()).left > 0);
    for (let i = 0; i < 12; i++) { await click('[data-rail-target=next]'); await sleep(450); }
    r = await rail();
    check("› greys out at the end", r.next && !r.prev);

    // 9. With no saved choice the page is light, even on a dark OS, and the
    //    toggle shows the sun.
    await send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: "dark" }] });
    await run(`localStorage.clear()`);
    await send("Page.reload");
    await sleep(2500);
    const theme = await run(`(() => { const shown = (n) => { const m = document.querySelector('header svg.lucide-' + n); return !!m && m.getBoundingClientRect().width > 0; };
      return { pref: document.documentElement.dataset.theme, dark: document.documentElement.classList.contains('dark'), sun: shown('sun'), monitor: shown('monitor') }; })()`);
    check("theme is light by default, even on a dark OS, with the sun icon", theme.pref === "light" && !theme.dark && theme.sun && !theme.monitor, JSON.stringify(theme));
    await send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: "light" }] });

    // 10. A hero switch flips with a real click, and its knob stays white in dark.
    await run(`(() => { const t = document.querySelector('[data-rail-target=track]'); const card = [...t.children].find(c => c.textContent.includes('Notifications'));
      t.scrollLeft = card.offsetLeft - t.offsetLeft; card.querySelector('label:has(input[role=switch])').setAttribute('data-test-switch', ''); })()`);
    await sleep(500);
    const switchOn = () => run(`document.querySelector('[data-test-switch] input').checked`);
    const before = await switchOn();
    await click("[data-test-switch] > span");
    await sleep(300);
    check("a hero switch flips on click", (await switchOn()) !== before);
    await run(`document.documentElement.classList.add('dark')`);
    await sleep(300);
    const knob = await run(`(() => { const k = document.querySelector('[data-test-switch] span[class*=translate-x]'); return { bg: getComputedStyle(k).backgroundColor, page: getComputedStyle(document.body).backgroundColor }; })()`);
    check("the knob is white in dark mode", /^rgb\(255, 255, 255\)/.test(knob.bg) && knob.page !== "rgb(255, 255, 255)", JSON.stringify(knob));
    await run(`document.documentElement.classList.remove('dark')`);

    // 11. The records card's pagination fits its card without overlapping.
    const pages = await run(`(() => { const nav = [...document.querySelectorAll('[data-rail-target=track] nav[aria-label]')].pop();
      const card = [...document.querySelector('[data-rail-target=track]').children].find(c => c.contains(nav)).getBoundingClientRect(); const ul = nav.querySelector('ul').getBoundingClientRect();
      const summary = [...nav.parentElement.querySelectorAll('*')].find(e => /Showing/.test(e.textContent) && e.children.length === 0).getBoundingClientRect();
      const overlap = !(summary.bottom <= ul.top || ul.bottom <= summary.top || summary.right <= ul.left || ul.right <= summary.left);
      return { overlap, inside: ul.left >= card.left && ul.right <= card.right && summary.right <= card.right }; })()`);
    check("hero pagination doesn't overlap and fits its card", !pages.overlap && pages.inside, JSON.stringify(pages));

    // 12. The collapsed sidebar keeps its mark square.
    await send("Page.navigate", { url: `${BASE}/docs/components/sidebar` });
    await sleep(2500);
    const mark = await run(`(() => { const img = [...document.querySelectorAll('[data-collapsible=icon] img[src*=mark]')].find(i => i.getBoundingClientRect().width > 0); const r = img.getBoundingClientRect(); return [Math.round(r.width), Math.round(r.height)]; })()`);
    check("the collapsed sidebar's mark isn't squashed", mark[0] === 28 && mark[1] === 28, mark.join("×"));
    //     Collapsing each example by its toggle centres the mark over the icons, unclipped.
    for (const id of ["preview-sidebar-default", "preview-sidebar-dropdown"]) {
      await run(`(() => { const aside = document.getElementById('${id}'); aside.scrollIntoView({ block: 'center' });
        aside.closest('[data-controller~="ui--sidebar"]').querySelector('[data-action~="ui--sidebar#toggle"]').setAttribute('data-test-toggle', ''); })()`);
      await sleep(300);
      await click("[data-test-toggle]");
      await sleep(600);
      const lined = await run(`(() => { const aside = document.getElementById('${id}'); document.querySelector('[data-test-toggle]').removeAttribute('data-test-toggle');
        const img = [...aside.querySelectorAll('img[src*=mark]')].find(i => i.getBoundingClientRect().width > 0); const m = img.getBoundingClientRect();
        const b = aside.querySelector('[data-sidebar=menu-button], [data-slot=sidebar-menu-button], ul a, ul button').getBoundingClientRect();
        const box = img.closest('[data-slot=sidebar-header]').getBoundingClientRect();
        return { collapsed: aside.dataset.collapsible, off: Math.round(Math.abs((m.left + m.right) / 2 - (b.left + b.right) / 2)), inside: m.left >= box.left && m.right <= box.right }; })()`);
      check(`collapsed ${id.replace("preview-sidebar-", "")} sidebar: mark centred over the icons`, lined.collapsed === "icon" && lined.off <= 1 && lined.inside, JSON.stringify(lined));
      if (process.env.UX_SHOTS) {
        const shot = await send("Page.captureScreenshot", { format: "png" });
        (await import("node:fs")).writeFileSync(`${process.env.UX_SHOTS}/${id}.png`, Buffer.from(shot.result.data, "base64"));
      }
    }

    // 13. The Menu page's examples stay inside the page.
    await send("Page.navigate", { url: `${BASE}/docs/components/menu` });
    await sleep(2500);
    const menu = await run(`(() => { const main = document.querySelector('main').getBoundingClientRect(); const h = [...document.querySelectorAll('h3')].find(e => e.textContent.trim() === 'Positions');
      const r = h.parentElement.getBoundingClientRect();
      return { inMain: !!h.closest('main'), left: Math.round(r.left - main.left), right: Math.round(main.right - r.right) }; })()`);
    check("the Menu page's Positions example stays inside the page", menu.inMain && menu.left >= 0 && menu.right >= 0, JSON.stringify(menu));

    // 14. A popover's arrow is the outline stepping out to a point, on every
    //     side: borders on its two outer edges only, its centre on the edge.
    await send("Page.navigate", { url: `${BASE}/docs/components/popover` });
    await sleep(2500);
    for (const side of ["Top", "Right", "Bottom", "Left"]) {
      await run(`(() => { const b = [...document.querySelectorAll('main button')].find(b => b.textContent.trim() === '${side}'); b.scrollIntoView({ block: 'center' }); b.setAttribute('data-test-popover', ''); })()`);
      await sleep(300);
      await click("[data-test-popover]");
      await sleep(400);
      const arrow = await run(`(() => { const t = document.querySelector('[data-test-popover]'); const c = t.closest('[data-controller~="ui--popover"]').querySelector('[role=dialog]');
        const a = c.querySelector('[data-ui--popover-target=arrow]'); const s = getComputedStyle(a); const ar = a.getBoundingClientRect(); const cr = c.getBoundingClientRect();
        const edges = ['Top', 'Right', 'Bottom', 'Left'].filter(e => parseFloat(s['border' + e + 'Width']) > 0).map(e => e[0].toLowerCase()).join('');
        const mid = { x: (ar.left + ar.right) / 2, y: (ar.top + ar.bottom) / 2 };
        const off = Math.round(Math.min(Math.abs(mid.y - cr.top), Math.abs(mid.y - cr.bottom), Math.abs(mid.x - cr.left), Math.abs(mid.x - cr.right)));
        t.removeAttribute('data-test-popover'); return { side: a.dataset.side, edges, off }; })()`);
      const want = { top: "rb", bottom: "tl", left: "tr", right: "bl" }[arrow.side];
      check(`popover arrow (${side}) borders only its point and sits on the edge`, arrow.edges === want && arrow.off <= 1, JSON.stringify(arrow));
      if (process.env.UX_SHOTS) {
        const shot = await send("Page.captureScreenshot", { format: "png" });
        (await import("node:fs")).writeFileSync(`${process.env.UX_SHOTS}/popover-${side.toLowerCase()}.png`, Buffer.from(shot.result.data, "base64"));
      }
      await key("Escape", "Escape", 0, 27);
      await sleep(300);
    }
  } catch (error) {
    console.log("ERROR", error.message);
    results.push(false);
  }
  console.log(`\n${results.filter(Boolean).length}/${results.length} passed`);
  ws.close();
  process.exit(results.every(Boolean) ? 0 : 1);
};
