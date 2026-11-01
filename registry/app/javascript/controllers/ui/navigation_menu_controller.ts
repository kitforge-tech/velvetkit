import { Controller } from '@hotwired/stimulus';
import { useFloating } from './_internal/use_floating.js';

/**
 * UI::NavigationMenu controller — disclosure navigation: triggers open a
 * panel of links below them. One panel is open at a time.
 *
 * Mouse: hover a trigger to open its panel after openDelay; once a panel is
 * open, hovering another trigger switches at once. A panel opened by hover
 * closes closeDelay after the pointer leaves trigger and panel (long enough
 * to cross the gap). One opened by click or keyboard stays until Escape, a
 * click outside or focus leaving — so moving the mouse away to scroll
 * doesn't close it. Click toggles (the only way in on touch).
 *
 * The panel opens below its trigger and flips above when there isn't room
 * below (a menu in a footer, or a header scrolled near the bottom), and
 * follows the trigger as the page or any container scrolls.
 *
 * Keyboard: Left/Right/Home/End move along the top row; Enter, Space or
 * ArrowDown on a trigger opens its panel (ArrowDown also focuses its first
 * link); Up/Down move between links in the panel; Escape closes and returns
 * focus to the trigger. Tabbing out of the nav, or clicking outside, closes.
 */
export default class extends Controller<HTMLElement> {
  static targets = ['top', 'trigger', 'panel', 'link'];
  static values = {
    openDelay: { type: Number, default: 150 },
    closeDelay: { type: Number, default: 200 },
  };

  declare readonly topTargets: HTMLElement[];
  declare readonly triggerTargets: HTMLButtonElement[];
  declare readonly panelTargets: HTMLElement[];
  declare openDelayValue: number;
  declare closeDelayValue: number;

  private openTrigger: HTMLButtonElement | null = null;
  private openedBy: 'hover' | 'click' | 'keyboard' | null = null;
  private openedByHoverAt = 0;
  private openTimer: number | null = null;
  private closeTimer: number | null = null;
  private floatingCleanup: (() => void) | null = null;

  disconnect() {
    this.close({ restoreFocus: false });
    this.clearTimers();
  }

  // ── Click ──────────────────────────────────────────────────────────────

  toggle(event: MouseEvent) {
    const trigger = event.currentTarget as HTMLButtonElement;
    this.clearTimers();
    if (this.openTrigger === trigger) {
      // A click that lands just after hover opened the panel is the user
      // reaching for it, not asking to close it.
      if (this.openedBy === 'hover' && Date.now() - this.openedByHoverAt < 400) {
        this.openedBy = 'click'; // the click claims it: no longer closes on leave
        return;
      }
      this.close({ restoreFocus: false });
    } else {
      // Enter/Space on a focused button also arrive as a click (detail 0).
      this.open(trigger, event.detail === 0 ? 'keyboard' : 'click');
    }
  }

  // ── Hover (mouse only) ─────────────────────────────────────────────────

  hoverOpen(event: PointerEvent) {
    if (event.pointerType !== 'mouse') return;
    const trigger = event.currentTarget as HTMLButtonElement;
    this.clearTimers();
    if (this.openTrigger === trigger) return;

    const show = () => {
      this.open(trigger, 'hover');
      this.openedByHoverAt = Date.now();
    };
    if (this.openTrigger) show(); // already browsing panels: switch at once
    else this.openTimer = window.setTimeout(show, this.openDelayValue);
  }

  hoverClose(event: PointerEvent) {
    if (event.pointerType !== 'mouse') return;
    this.clearOpenTimer();
    if (!this.openTrigger || this.openedBy !== 'hover') return;
    this.clearCloseTimer();
    this.closeTimer = window.setTimeout(() => this.close({ restoreFocus: false }), this.closeDelayValue);
  }

  cancelClose() {
    this.clearCloseTimer();
  }

  // ── Keyboard ───────────────────────────────────────────────────────────

  topKeydown(event: KeyboardEvent) {
    const item = event.currentTarget as HTMLElement;
    const tops = this.topTargets;
    const index = tops.indexOf(item);
    const isTrigger = this.triggerTargets.includes(item as HTMLButtonElement);

    switch (event.key) {
      case 'ArrowRight':
        this.focusTop(tops[(index + 1) % tops.length]);
        break;
      case 'ArrowLeft':
        this.focusTop(tops[(index - 1 + tops.length) % tops.length]);
        break;
      case 'Home':
        this.focusTop(tops[0]);
        break;
      case 'End':
        this.focusTop(tops[tops.length - 1]);
        break;
      case 'ArrowDown':
        if (!isTrigger) return;
        this.open(item as HTMLButtonElement, 'keyboard');
        this.linksOf(this.panelFor(item as HTMLButtonElement))[0]?.focus();
        break;
      case 'Escape':
        if (!this.openTrigger) return;
        this.close({ restoreFocus: true });
        break;
      default:
        return;
    }
    event.preventDefault();
  }

  panelKeydown(event: KeyboardEvent) {
    const panel = event.currentTarget as HTMLElement;
    const links = this.linksOf(panel);
    const index = links.indexOf(document.activeElement as HTMLElement);

    switch (event.key) {
      case 'ArrowDown':
        links[(index + 1) % links.length]?.focus();
        break;
      case 'ArrowUp':
        if (index <= 0) this.openTrigger?.focus();
        else links[index - 1]?.focus();
        break;
      case 'Home':
        links[0]?.focus();
        break;
      case 'End':
        links[links.length - 1]?.focus();
        break;
      case 'Escape':
        this.close({ restoreFocus: true });
        break;
      default:
        return;
    }
    event.preventDefault();
  }

  // Focus landed somewhere that isn't the open panel or its trigger — the
  // next top-level item after Tabbing past the last link, or anything else
  // on the page — so the panel no longer belongs to where the user is.
  focusIn(event: FocusEvent) {
    this.closeUnlessWithinOpen(event.target as Node);
  }

  focusOut(event: FocusEvent) {
    const next = event.relatedTarget as Node | null;
    // Focus went nowhere (a click on plain page): the outside-pointer
    // handler decides. Moving within the nav: focusIn decides.
    if (next === null || this.element.contains(next)) return;
    this.close({ restoreFocus: false });
  }

  private closeUnlessWithinOpen(node: Node) {
    const trigger = this.openTrigger;
    if (!trigger) return;
    if (trigger.contains(node) || this.panelFor(trigger)?.contains(node)) return;
    this.close({ restoreFocus: false });
  }

  // ── Open / close ───────────────────────────────────────────────────────

  private open(trigger: HTMLButtonElement, by: 'hover' | 'click' | 'keyboard') {
    if (this.openTrigger === trigger) return;
    this.close({ restoreFocus: false });

    const panel = this.panelFor(trigger);
    if (!panel) return;

    panel.hidden = false;
    panel.dataset.state = 'open';
    trigger.setAttribute('aria-expanded', 'true');
    this.floatingCleanup = useFloating(trigger, panel, {
      placement: 'bottom-start',
      offset: 6,
      flip: true,
      shift: true,
      strategy: 'fixed',
    }).destroy;

    this.openTrigger = trigger;
    this.openedBy = by;
    document.addEventListener('pointerdown', this.onOutsidePointer, true);
  }

  private close({ restoreFocus }: { restoreFocus: boolean }) {
    const trigger = this.openTrigger;
    if (!trigger) return;
    const panel = this.panelFor(trigger);

    this.floatingCleanup?.();
    this.floatingCleanup = null;
    if (panel) {
      panel.hidden = true;
      panel.dataset.state = 'closed';
    }
    trigger.setAttribute('aria-expanded', 'false');
    this.openTrigger = null;
    this.openedBy = null;
    this.openedByHoverAt = 0;
    document.removeEventListener('pointerdown', this.onOutsidePointer, true);
    if (restoreFocus) trigger.focus();
  }

  private onOutsidePointer = (event: PointerEvent) => {
    if (this.element.contains(event.target as Node)) return;
    this.close({ restoreFocus: false });
  };

  // ── Helpers ────────────────────────────────────────────────────────────

  private panelFor(trigger: HTMLButtonElement): HTMLElement | null {
    const id = trigger.getAttribute('aria-controls');
    return this.panelTargets.find((p) => p.id === id) ?? null;
  }

  private linksOf(panel: HTMLElement | null): HTMLElement[] {
    if (!panel) return [];
    return Array.from(panel.querySelectorAll<HTMLElement>('a[href], button:not([disabled])'));
  }

  // Moving along the top row closes a panel left behind, so an open panel
  // always belongs to the item with focus.
  private focusTop(item: HTMLElement | undefined) {
    if (!item) return;
    if (this.openTrigger && item !== this.openTrigger) this.close({ restoreFocus: false });
    item.focus();
  }

  private clearOpenTimer() {
    if (this.openTimer !== null) window.clearTimeout(this.openTimer);
    this.openTimer = null;
  }

  private clearCloseTimer() {
    if (this.closeTimer !== null) window.clearTimeout(this.closeTimer);
    this.closeTimer = null;
  }

  private clearTimers() {
    this.clearOpenTimer();
    this.clearCloseTimer();
  }
}
