import { Controller } from '@hotwired/stimulus';
import { ariaShortcut, isApple, isTyping, keyboardPlatform, matchesShortcut, parseShortcut, usableWhileTyping, type Shortcut } from './_internal/shortcut.js';

// Connects to data-controller="ui--kbd"
//
// The server guesses Mac or not from the user agent; this corrects the guess,
// in case the page was cached for someone else. With a keys value (bind: on
// the component) it also makes the shortcut press its button: the one the
// hint sits in, or the element the target value points at. A field the
// target points at is focused instead.
export default class extends Controller<HTMLElement> {
  static values = { keys: String, target: String };

  declare readonly keysValue: string;
  declare readonly hasKeysValue: boolean;
  declare readonly targetValue: string;

  private apple = false;
  private shortcut?: Shortcut;
  private bound?: HTMLElement;
  private addedAria = false;

  connect() {
    this.apple = isApple();
    this.element.dataset.platform = keyboardPlatform();
    if (!this.hasKeysValue || !this.keysValue) return;

    this.bound = this.findTarget();
    if (!this.bound) return;
    this.shortcut = parseShortcut(this.keysValue);
    if (!this.bound.hasAttribute('aria-keyshortcuts')) {
      this.bound.setAttribute('aria-keyshortcuts', ariaShortcut(this.shortcut, this.apple));
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
    if (event.defaultPrevented || event.repeat || event.isComposing || !this.bound || !this.shortcut) return;
    if (!matchesShortcut(event, this.shortcut, this.apple)) return;
    if (isTyping(event.target) && !usableWhileTyping(this.shortcut)) return;
    if (this.bound.matches(':disabled, [aria-disabled="true"], [data-disabled]')) return;

    event.preventDefault();
    if (this.bound.matches('input, textarea, select, [contenteditable="true"]')) this.bound.focus();
    else this.bound.click();
  };

  private findTarget(): HTMLElement | undefined {
    if (this.targetValue) return document.querySelector<HTMLElement>(this.targetValue) ?? undefined;
    return this.element.closest<HTMLElement>('button, a[href], [role="menuitem"], [role="option"], input[type="submit"]') ?? undefined;
  }
}
