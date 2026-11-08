// Keyboard shortcuts written the way UI::Kbd writes them: "mod+k",
// "shift+enter", "alt+c", "/". "mod" is ⌘ on a Mac and Ctrl elsewhere.
const MODIFIERS = ['mod', 'cmd', 'ctrl', 'alt', 'shift'] as const;
type Modifier = (typeof MODIFIERS)[number];

const ALIASES: Record<string, string> = {
  command: 'cmd', meta: 'cmd', control: 'ctrl', option: 'alt', opt: 'alt', return: 'enter',
  escape: 'esc', del: 'delete', arrowup: 'up', arrowdown: 'down', arrowleft: 'left', arrowright: 'right',
};

// What KeyboardEvent.key says for the named keys.
const EVENT_KEYS: Record<string, string> = {
  enter: 'enter', esc: 'escape', tab: 'tab', space: ' ', backspace: 'backspace', delete: 'delete',
  up: 'arrowup', down: 'arrowdown', left: 'arrowleft', right: 'arrowright',
};

// aria-keyshortcuts spells keys the way KeyboardEvent.key does.
const ARIA_NAMES: Record<string, string> = {
  cmd: 'Meta', ctrl: 'Control', alt: 'Alt', shift: 'Shift', enter: 'Enter', esc: 'Escape', tab: 'Tab',
  space: 'Space', backspace: 'Backspace', delete: 'Delete', up: 'ArrowUp', down: 'ArrowDown',
  left: 'ArrowLeft', right: 'ArrowRight',
};

export type Shortcut = { mods: Set<Modifier>; key: string };

export const isApple = () => {
  const nav = navigator as Navigator & { userAgentData?: { platform?: string } };
  return /mac|iphone|ipad|ipod/i.test(nav.userAgentData?.platform || navigator.platform || navigator.userAgent);
};

export const parseShortcut = (keys: string): Shortcut => {
  const names = keys.split('+').map((part) => part.trim().toLowerCase()).filter(Boolean).map((part) => ALIASES[part] ?? part);
  const isMod = (n: string): n is Modifier => (MODIFIERS as readonly string[]).includes(n);
  return { mods: new Set(names.filter(isMod)), key: names.filter((n) => !isMod(n)).pop() ?? '' };
};

// Modifiers have to match exactly, so Ctrl+S isn't ⌘S on a Mac.
export const matchesShortcut = (event: KeyboardEvent, { mods, key }: Shortcut, apple = isApple()) => {
  const wantMeta = mods.has('cmd') || (mods.has('mod') && apple);
  const wantCtrl = mods.has('ctrl') || (mods.has('mod') && !apple);
  if (event.metaKey !== wantMeta || event.ctrlKey !== wantCtrl || event.altKey !== mods.has('alt')) return false;

  // Letters and digits by their place on the keyboard: Option on a Mac turns
  // "k" into "˚". Shift has to match for these.
  if (/^[a-z]$/.test(key)) return event.shiftKey === mods.has('shift') && event.code === `Key${key.toUpperCase()}`;
  if (/^[0-9]$/.test(key)) return event.shiftKey === mods.has('shift') && event.code === `Digit${key}`;

  const named = EVENT_KEYS[key];
  if (named) return event.shiftKey === mods.has('shift') && event.key.toLowerCase() === named;
  // A symbol, like "?" or "/": the character typed, whatever it took to type it.
  return event.key.toLowerCase() === key;
};

// A shortcut with mod, ctrl or alt still works while typing in a field; a
// bare key is typing.
export const usableWhileTyping = ({ mods }: Shortcut) => mods.has('mod') || mods.has('ctrl') || mods.has('alt') || mods.has('cmd');

export const isTyping = (target: EventTarget | null) => {
  if (!(target instanceof HTMLElement)) return false;
  return target.isContentEditable ||
    target.matches('input:not([type="checkbox"], [type="radio"], [type="button"], [type="submit"]), textarea, select');
};

export const ariaShortcut = ({ mods, key }: Shortcut, apple = isApple()) => {
  const names = [...mods].map((mod) => (mod === 'mod' ? (apple ? 'Meta' : 'Control') : ARIA_NAMES[mod]));
  names.push(ARIA_NAMES[key] ?? (key.length === 1 ? key.toUpperCase() : key));
  return names.join('+');
};
