import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--kbd"
//
// The server guesses Mac or not from the user agent; this corrects the guess,
// in case the page was cached for someone else. With a keys value (bind: on
// the component) it also makes the shortcut press its button: the one the
// hint sits in, or the element the target value points at. A field the
// target points at is focused instead.
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

const isApple = () => {
  const nav = navigator as Navigator & { userAgentData?: { platform?: string } };
  return /mac|iphone|ipad|ipod/i.test(nav.userAgentData?.platform || navigator.platform || navigator.userAgent);
};

export default class extends Controller<HTMLElement> {
  static values = { keys: String, target: String };

  declare readonly keysValue: string;
  declare readonly hasKeysValue: boolean;
  declare readonly targetValue: string;

  private apple = false;
  private bound?: HTMLElement;
  private addedAria = false;

  connect() {
    this.apple = isApple();
    this.element.dataset.platform = this.apple ? 'mac' : 'other';
    if (!this.hasKeysValue || !this.keysValue) return;

    this.bound = this.findTarget();
    if (!this.bound) return;
    if (!this.bound.hasAttribute('aria-keyshortcuts')) {
      this.bound.setAttribute('aria-keyshortcuts', this.ariaShortcut());
      this.addedAria = true;
    }
    document.addEventListener('keydown', this.onKeydown);
  }

  disconnect() {
    document.removeEventListener('keydown', this.onKeydown);
    if (this.addedAria) this.bound?.removeAttribute('aria-keyshortcuts');
    this.bound = undefined;
    this.addedAria = false;
  }

  private onKeydown = (event: KeyboardEvent) => {
    if (event.defaultPrevented || event.repeat || event.isComposing || !this.bound) return;
    if (!this.matches(event)) return;

    const { mods } = this.parsed();
    // Typing a letter in a field is typing, not a shortcut.
    if (this.isTyping(event.target) && !mods.has('mod') && !mods.has('ctrl') && !mods.has('alt') && !mods.has('cmd')) return;
    if (this.bound.matches(':disabled, [aria-disabled="true"], [data-disabled]')) return;

    event.preventDefault();
    // A field is focused, like "/" for search; anything else is pressed.
    if (this.bound.matches('input, textarea, select, [contenteditable="true"]')) this.bound.focus();
    else this.bound.click();
  };

  private findTarget(): HTMLElement | undefined {
    if (this.targetValue) return document.querySelector<HTMLElement>(this.targetValue) ?? undefined;
    return this.element.closest<HTMLElement>('button, a[href], [role="menuitem"], input[type="submit"]') ?? undefined;
  }

  private parsed() {
    const parts = this.keysValue.split('+').map((part) => part.trim().toLowerCase()).filter(Boolean);
    const names = parts.map((part) => ALIASES[part] ?? part);
    const mods = new Set(names.filter((n): n is Modifier => (MODIFIERS as readonly string[]).includes(n)));
    const key = names.filter((n) => !(MODIFIERS as readonly string[]).includes(n)).pop() ?? '';
    return { mods, key };
  }

  private matches(event: KeyboardEvent) {
    const { mods, key } = this.parsed();
    const wantMeta = mods.has('cmd') || (mods.has('mod') && this.apple);
    const wantCtrl = mods.has('ctrl') || (mods.has('mod') && !this.apple);
    if (event.metaKey !== wantMeta || event.ctrlKey !== wantCtrl || event.altKey !== mods.has('alt')) return false;

    // Letters and digits by their place on the keyboard: Option on a Mac turns
    // "k" into "˚". Shift has to match for these.
    if (/^[a-z]$/.test(key)) return event.shiftKey === mods.has('shift') && event.code === `Key${key.toUpperCase()}`;
    if (/^[0-9]$/.test(key)) return event.shiftKey === mods.has('shift') && event.code === `Digit${key}`;

    const named = EVENT_KEYS[key];
    if (named) return event.shiftKey === mods.has('shift') && event.key.toLowerCase() === named;
    // A symbol, like "?" or "/": the character typed, whatever it took to type it.
    return event.key.toLowerCase() === key;
  }

  private isTyping(target: EventTarget | null) {
    if (!(target instanceof HTMLElement)) return false;
    return target.isContentEditable || target.matches('input:not([type="checkbox"], [type="radio"], [type="button"], [type="submit"]), textarea, select');
  }

  private ariaShortcut() {
    const { mods, key } = this.parsed();
    const names = [...mods].map((mod) => (mod === 'mod' ? (this.apple ? 'Meta' : 'Control') : ARIA_NAMES[mod]));
    names.push(ARIA_NAMES[key] ?? (key.length === 1 ? key.toUpperCase() : key));
    return names.join('+');
  }
}
