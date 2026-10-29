// Every Lucide icon, for the docs only. The live examples use icons the kit's
// own velvetkit_icons.ts doesn't list, and a docs site can afford the bytes;
// an app should list just the icons it uses, as velvetkit_icons.ts does.
import { createIcons, icons } from "lucide"

// Drawn whenever an icon is added, however it arrives (a Turbo visit, frame
// or stream, or a controller's markup). Only <i> is watched: the SVG that
// replaces it keeps data-lucide, and drawing on that would never stop.
const draw = () => createIcons({ icons })
draw()
new MutationObserver((records) => {
  if (records.some((r) => [...r.addedNodes].some((n) => n instanceof Element && (n.matches("i[data-lucide]") || n.querySelector("i[data-lucide]"))))) draw()
}).observe(document.documentElement, { childList: true, subtree: true })
