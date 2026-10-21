// Every Lucide icon, for the docs only. The live examples use icons the kit's
// own velvetkit_icons.ts doesn't list, and a docs site can afford the bytes;
// an app should list just the icons it uses, as velvetkit_icons.ts does.
import { createIcons, icons } from "lucide"

const draw = () => createIcons({ icons })
;["turbo:load", "turbo:frame-load", "turbo:render", "turbo:submit-end", "turbo:render-stream"]
  .forEach((event) => document.addEventListener(event, draw))
