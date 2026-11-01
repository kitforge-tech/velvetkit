import { Controller } from '@hotwired/stimulus';

/**
 * UI::SessionTabs controller — tabs the user opens, renames, duplicates,
 * reorders and closes.
 *
 * Every action first dispatches a cancelable `ui--session-tabs:<action>`
 * event (select, add, rename, duplicate, move, close) on the tab — or on the
 * root, for `add` — with `{ value, url, ... }` in `detail`.
 * `preventDefault()` stops it. Then:
 *   - if the tab carries a URL for that action, a Turbo-compatible form is
 *     submitted (rename PATCH, duplicate POST, move PATCH, close DELETE) and
 *     the server re-renders;
 *   - otherwise the event *is* the action, and the controller applies what it
 *     can locally: select, rename, move and close update the DOM; duplicate
 *     and add need markup only the app has, so they only dispatch.
 *
 * Reordering: tabs with `move:` can be dragged — anywhere on the tab with a
 * mouse, by the grip handle on touch — or moved from the menu. Tabs without it are
 * fixed points that movable tabs never pass. The drop fires the same `move`
 * event with the new 1-based `position`.
 */

type MenuController = Controller & { open(): void; close(): void };
type DialogController = Controller & { open(): void; close(): void };

const TAB = '[data-ui--session-tabs-target="tab"]';
const TRIGGER = '[data-ui--session-tabs-target="trigger"]';
const LABEL = '[data-ui--session-tabs-target="label"]';
const MENU_TRIGGER = '[data-ui--session-tabs-target="menuTrigger"]';
const LONG_PRESS_MS = 450;
const DRAG_THRESHOLD = 6; // px before a press becomes a drag
const EDGE = 32; // px from the list edge where dragging scrolls it

type Press = {
  tab: HTMLElement;
  kind: 'drag' | 'longPress'; // drag: handle, or tab body with a mouse; longPress: tab body on touch
  touch: boolean;
  pointerId: number;
  startX: number;
  startY: number;
  armed: boolean; // drag: at once; longPress: after LONG_PRESS_MS
  timer: number | null;
  cancelled: boolean; // drag cancelled with Escape; ignore until release
};

type Drag = {
  tab: HTMLElement;
  grabOffset: number;
  originNext: Element | null;
  originIndex: number;
  offset: number;
};

export default class extends Controller<HTMLElement> {
  static targets = ['list', 'tab', 'dialog', 'confirmMessage'];
  static values = {
    minTabs: { type: Number, default: 1 },
    returnFocus: String,
    renameParam: { type: String, default: 'name' },
    renameLabel: { type: String, default: 'Tab name' },
  };

  declare readonly listTarget: HTMLElement;
  declare readonly tabTargets: HTMLElement[];
  declare readonly dialogTarget: HTMLElement;
  declare readonly confirmMessageTarget: HTMLElement;
  declare minTabsValue: number;
  declare returnFocusValue: string;
  declare renameParamValue: string;
  declare renameLabelValue: string;

  private press: Press | null = null;
  private drag: Drag | null = null;
  private suppressClick = false;
  private suppressTimer: number | null = null;
  private pendingMenu: { tab: HTMLElement; timer: number } | null = null;
  private pendingClose: HTMLElement | null = null;

  connect() {
    this.sync();
    this.activeTab()?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  }

  disconnect() {
    if (this.drag) this.finishDrag(false);
    this.endPress();
    if (this.pendingMenu) window.clearTimeout(this.pendingMenu.timer);
    if (this.suppressTimer != null) window.clearTimeout(this.suppressTimer);
  }

  // Tabs added or removed from outside (a Turbo Stream, the app's own JS)
  // still need Close/Move and the tabindex re-derived.
  tabTargetConnected() {
    this.sync();
  }

  tabTargetDisconnected() {
    this.sync();
  }

  // ── Selecting ──────────────────────────────────────────────────────────

  select(event: MouseEvent) {
    if (this.pendingMenu) {
      // The click after a touch long-press: open the menu now, from inside
      // this click, so UI::Menu's outside-click check doesn't see it.
      const { tab, timer } = this.pendingMenu;
      window.clearTimeout(timer);
      this.pendingMenu = null;
      event.preventDefault();
      this.menuOf(tab)?.open();
      return;
    }
    if (this.suppressClick) {
      // The click that ends a drag; don't also select.
      event.preventDefault();
      return;
    }
    const tab = this.tabFor(event.currentTarget);
    if (!tab) return;
    if (!this.emit('select', tab, { url: this.triggerOf(tab)?.getAttribute('href') ?? null })) {
      event.preventDefault();
      return;
    }
    // A link navigates and the server marks the new tab active; a button
    // tab is switched here.
    if (!this.isLink(tab)) this.activate(tab);
    this.restoreFocus();
  }

  // Arrow keys move focus only (manual activation): selecting a tab may load
  // a whole pane, so Enter/Space — or a click — commits.
  keydown(event: KeyboardEvent) {
    const tab = this.tabFor(event.currentTarget);
    if (!tab) return;
    const triggers = this.tabTargets.map((t) => this.triggerOf(t)!).filter(Boolean);
    const index = triggers.indexOf(event.currentTarget as HTMLElement);
    let next = -1;

    switch (event.key) {
      case 'ArrowRight':
        next = (index + 1) % triggers.length;
        break;
      case 'ArrowLeft':
        next = (index - 1 + triggers.length) % triggers.length;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = triggers.length - 1;
        break;
      case 'F2':
        if (tab.dataset.renameEnabled) {
          event.preventDefault();
          this.startRename(tab);
        }
        return;
      case 'ContextMenu':
        event.preventDefault();
        this.menuOf(tab)?.open();
        return;
      case 'F10':
        if (event.shiftKey) {
          event.preventDefault();
          this.menuOf(tab)?.open();
        }
        return;
      default:
        return;
    }

    event.preventDefault();
    const target = triggers[next];
    if (!target) return;
    triggers.forEach((t) => t.setAttribute('tabindex', t === target ? '0' : '-1'));
    target.focus();
    target.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  }

  // ── Pointer: drag handle, long-press menu ───────────────────────────
  //
  // Mouse/pen: press anywhere on a movable tab and move to drag; a plain
  // click still selects. Touch: drag by the grip handle (it is
  // `touch-action: none`, so a finger drags it at once) — the rest of the
  // tab scrolls the list on swipe and opens the menu on a long-press.

  contextMenu(event: MouseEvent) {
    const tab = this.tabFor(event.currentTarget);
    const menu = tab && this.menuOf(tab);
    if (!menu) return;
    event.preventDefault();
    // On touch the long-press logic below opens it (Android also fires
    // contextmenu for the same press).
    if (this.press?.touch) return;
    menu.open();
  }

  // Tab body: mouse/pen → drag (after DRAG_THRESHOLD, so clicks still
  // select); touch → long-press menu.
  pressStart(event: PointerEvent) {
    if (event.button !== 0 || this.press) return;
    const tab = this.tabFor(event.currentTarget);
    if (!tab) return;
    if (event.pointerType !== 'touch') {
      if (tab.dataset.moveEnabled) this.beginPress(event, tab, 'drag');
      return;
    }
    if (!this.menuOf(tab)) return;
    this.beginPress(event, tab, 'longPress');
    this.press!.timer = window.setTimeout(() => {
      if (this.press) this.press.armed = true;
    }, LONG_PRESS_MS);
  }

  // Grip handle → drag.
  dragStart(event: PointerEvent) {
    if (event.button !== 0 || this.press) return;
    const tab = this.tabFor(event.currentTarget);
    if (!tab || !tab.dataset.moveEnabled) return;
    event.preventDefault(); // no text selection, no focus change
    this.beginPress(event, tab, 'drag');
  }

  private beginPress(event: PointerEvent, tab: HTMLElement, kind: Press['kind']) {
    this.press = {
      tab,
      kind,
      touch: event.pointerType === 'touch',
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      armed: kind === 'drag',
      timer: null,
      cancelled: false,
    };
    window.addEventListener('pointermove', this.onPointerMove);
    window.addEventListener('pointerup', this.onPointerUp);
    window.addEventListener('pointercancel', this.onPointerCancel);
    window.addEventListener('keydown', this.onDragKeydown, true);
    // Stops the list scrolling while a long-press is armed or a drag runs.
    this.element.addEventListener('touchmove', this.onTouchMove, { passive: false });
  }

  private onPointerMove = (event: PointerEvent) => {
    const press = this.press;
    if (!press || event.pointerId !== press.pointerId || press.cancelled) return;

    if (this.drag) {
      this.updateDrag(event.clientX);
      return;
    }
    const moved = Math.hypot(event.clientX - press.startX, event.clientY - press.startY);
    if (moved < DRAG_THRESHOLD) return;

    if (press.kind === 'drag') {
      this.beginDrag(event.clientX);
      this.updateDrag(event.clientX);
    } else {
      // The finger moved: a scroll (before the long-press fired) or a
      // change of mind (after). Either way, no menu.
      this.endPress();
    }
  };

  private onPointerUp = (event: PointerEvent) => {
    const press = this.press;
    if (!press || event.pointerId !== press.pointerId) return;
    if (this.drag) {
      this.finishDrag(true);
      this.suppressNextClick();
    } else if (press.cancelled) {
      this.suppressNextClick();
    } else if (press.kind === 'longPress' && press.armed) {
      // A click may or may not follow a long-press; open from that click if
      // it comes (see select), otherwise shortly after.
      const tab = press.tab;
      const timer = window.setTimeout(() => {
        this.pendingMenu = null;
        this.menuOf(tab)?.open();
      }, 350);
      this.pendingMenu = { tab, timer };
    }
    this.endPress();
  };

  private onPointerCancel = () => {
    if (this.drag) this.finishDrag(false);
    this.endPress();
  };

  private onDragKeydown = (event: KeyboardEvent) => {
    if (event.key !== 'Escape' || !this.drag) return;
    event.preventDefault();
    event.stopPropagation();
    this.finishDrag(false);
    if (this.press) this.press.cancelled = true;
  };

  // The click that follows pointerup arrives in the same task, if at all, so
  // the flag is cleared on the next one — a click that lands elsewhere
  // can't leave it set and swallow the user's next real click.
  private suppressNextClick() {
    this.suppressClick = true;
    if (this.suppressTimer != null) window.clearTimeout(this.suppressTimer);
    this.suppressTimer = window.setTimeout(() => {
      this.suppressClick = false;
      this.suppressTimer = null;
    }, 0);
  }

  private onTouchMove = (event: TouchEvent) => {
    if (this.press?.armed || this.drag) event.preventDefault();
  };

  private endPress() {
    if (this.press?.timer != null) window.clearTimeout(this.press.timer);
    this.press = null;
    window.removeEventListener('pointermove', this.onPointerMove);
    window.removeEventListener('pointerup', this.onPointerUp);
    window.removeEventListener('pointercancel', this.onPointerCancel);
    window.removeEventListener('keydown', this.onDragKeydown, true);
    this.element.removeEventListener('touchmove', this.onTouchMove);
  }

  private beginDrag(clientX: number) {
    const tab = this.press!.tab;
    const rect = tab.getBoundingClientRect();
    this.drag = {
      tab,
      grabOffset: clientX - rect.left,
      originNext: tab.nextElementSibling,
      originIndex: this.tabTargets.indexOf(tab),
      offset: 0,
    };
    tab.dataset.dragging = '';
    this.menuOf(tab)?.close();
  }

  private updateDrag(clientX: number) {
    const drag = this.drag!;
    const { tab } = drag;

    // Where the dragged tab is drawn right now, in client coordinates.
    const left = clientX - drag.grabOffset;
    const right = left + tab.offsetWidth;

    // Neighbours are compared by their *layout* slot (offsetLeft), never
    // their on-screen rect: a neighbour still sliding from the last swap
    // would otherwise be measured mid-animation and swap straight back.
    // `toClient` converts offset coordinates to client ones.
    const toClient = tab.getBoundingClientRect().left - drag.offset - tab.offsetLeft;
    const centre = (t: HTMLElement) => toClient + t.offsetLeft + t.offsetWidth / 2;

    // Swap as soon as the dragged tab covers half of the next movable tab —
    // its leading edge, not the pointer, decides — and keep going on a fast
    // drag that passes several tabs at once.
    for (let guard = this.tabTargets.length; guard > 0; guard--) {
      const next = this.movableNeighbour(tab, 1);
      const prev = this.movableNeighbour(tab, -1);
      if (next && right > centre(next)) {
        this.animateSiblings(() => next.after(tab));
      } else if (prev && left < centre(prev)) {
        this.animateSiblings(() => prev.before(tab));
      } else {
        break;
      }
    }

    // Keep the dragged tab under the pointer wherever its slot now is.
    const naturalLeft = tab.getBoundingClientRect().left - drag.offset;
    drag.offset = left - naturalLeft;
    tab.style.transform = `translateX(${drag.offset}px)`;

    this.autoScroll(clientX);
  }

  private finishDrag(commit: boolean) {
    const drag = this.drag!;
    const { tab } = drag;
    this.drag = null;
    delete tab.dataset.dragging;
    tab.style.transform = '';

    const to = this.tabTargets.indexOf(tab);
    const moved = to !== drag.originIndex;
    const allowed =
      commit &&
      moved &&
      this.emit('move', tab, {
        position: to + 1,
        direction: to < drag.originIndex ? 'left' : 'right',
      });

    if (moved && !allowed) {
      // Cancelled (Escape, pointercancel, or preventDefault): put it back.
      this.animateSiblings(() => {
        if (drag.originNext) drag.originNext.before(tab);
        else this.listTarget.append(tab);
      });
    }
    this.sync();
    if (allowed && tab.dataset.moveUrl) {
      this.submit(tab.dataset.moveUrl, 'patch', { position: String(to + 1) });
    }
  }

  // FLIP: neighbours slide into their new slots instead of jumping.
  private animateSiblings(mutate: () => void) {
    const others = this.tabTargets.filter((t) => t !== this.drag?.tab);
    // "Before" is where each tab is *drawn* (mid-slide included), so a new
    // slide continues from there instead of jumping.
    const before = new Map(others.map((t) => [t, t.getBoundingClientRect().left]));
    mutate();
    for (const t of others) {
      // Measure the new slot without the old slide still applied.
      t.getAnimations().forEach((a) => a.cancel());
      const dx = (before.get(t) ?? 0) - t.getBoundingClientRect().left;
      if (!dx) continue;
      t.animate([{ transform: `translateX(${dx}px)` }, { transform: 'translateX(0)' }], {
        duration: 150,
        easing: 'ease-out',
      });
    }
  }

  private autoScroll(clientX: number) {
    const list = this.listTarget.getBoundingClientRect();
    if (clientX < list.left + EDGE) this.listTarget.scrollLeft -= 8;
    else if (clientX > list.right - EDGE) this.listTarget.scrollLeft += 8;
  }

  // ── Menu actions ───────────────────────────────────────────────────────

  rename(event: Event) {
    const tab = this.fromMenu(event);
    if (tab) this.startRename(tab);
  }

  duplicate(event: Event) {
    const tab = this.fromMenu(event);
    if (!tab || !this.emit('duplicate', tab)) return;
    if (tab.dataset.duplicateUrl) this.submit(tab.dataset.duplicateUrl, 'post');
  }

  moveLeft(event: Event) {
    const tab = this.fromMenu(event);
    if (tab) this.move(tab, -1);
  }

  moveRight(event: Event) {
    const tab = this.fromMenu(event);
    if (tab) this.move(tab, 1);
  }

  close(event: Event) {
    const tab = this.fromMenu(event);
    if (!tab || !this.canClose()) return;
    const message = tab.dataset.closeConfirm;
    if (message) {
      this.pendingClose = tab;
      this.confirmMessageTarget.textContent = message;
      this.dialog()?.open();
    } else {
      this.performClose(tab);
    }
  }

  confirmClose(event: Event) {
    event.preventDefault();
    this.dialog()?.close();
    const tab = this.pendingClose;
    this.pendingClose = null;
    if (tab) this.performClose(tab);
  }

  add(event: Event) {
    // With a URL the button submits its own form; cancelling the event
    // cancels the submit.
    if (!this.emit('add', null)) event.preventDefault();
  }

  // ── Rename ─────────────────────────────────────────────────────────────

  private startRename(tab: HTMLElement) {
    const trigger = this.triggerOf(tab);
    const label = tab.querySelector<HTMLElement>(LABEL);
    if (!trigger || !label || tab.querySelector('input[data-session-tabs-rename]')) return;

    const original = (label.textContent ?? '').trim();
    const input = document.createElement('input');
    input.type = 'text';
    input.value = original;
    input.dataset.sessionTabsRename = '';
    input.setAttribute('aria-label', this.renameLabelValue);
    input.className =
      'mx-1 h-[calc(100%-0.5rem)] min-w-0 w-[16ch] rounded-sm border border-input bg-background px-2 ' +
      'text-sm text-foreground outline-none focus:ring-2 focus:ring-primary';

    let done = false;
    const finish = (commit: boolean) => {
      if (done) return;
      done = true;
      const name = input.value.trim();
      input.remove();
      trigger.hidden = false;
      if (commit && name && name !== original) this.commitRename(tab, label, name);
      trigger.focus();
      if (commit) this.restoreFocus();
    };

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        finish(true);
      } else if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        finish(false);
      }
    });
    input.addEventListener('blur', () => finish(true));

    trigger.hidden = true;
    tab.insertBefore(input, trigger);
    input.focus();
    input.select();
  }

  private commitRename(tab: HTMLElement, label: HTMLElement, name: string) {
    if (!this.emit('rename', tab, { name })) return;
    label.textContent = name;
    if (tab.dataset.renameUrl) {
      this.submit(tab.dataset.renameUrl, 'patch', { [this.renameParamValue]: name });
    }
  }

  // ── Move ───────────────────────────────────────────────────────────────

  private move(tab: HTMLElement, step: -1 | 1) {
    const neighbour = this.movableNeighbour(tab, step);
    if (!neighbour) return;

    const originNext = tab.nextElementSibling;
    if (step < 0) neighbour.before(tab);
    else neighbour.after(tab);
    const position = this.tabTargets.indexOf(tab) + 1; // 1-based, like acts_as_list / positioning

    if (!this.emit('move', tab, { position, direction: step < 0 ? 'left' : 'right' })) {
      // Cancelled: put it back where it was.
      if (originNext) originNext.before(tab);
      else this.listTarget.append(tab);
      return;
    }
    this.sync();
    this.triggerOf(tab)?.focus();
    tab.scrollIntoView({ block: 'nearest', inline: 'nearest' });

    if (tab.dataset.moveUrl) this.submit(tab.dataset.moveUrl, 'patch', { position: String(position) });
  }

  // Non-movable tabs are fixed points: moves hop over them.
  private movableNeighbour(tab: HTMLElement, step: -1 | 1): HTMLElement | null {
    const tabs = this.tabTargets;
    for (let i = tabs.indexOf(tab) + step; i >= 0 && i < tabs.length; i += step) {
      if (tabs[i]!.dataset.moveEnabled) return tabs[i]!;
    }
    return null;
  }

  // ── Close ──────────────────────────────────────────────────────────────

  private canClose() {
    return this.tabTargets.length > this.minTabsValue;
  }

  private performClose(tab: HTMLElement) {
    if (!this.emit('close', tab)) return;

    // With a URL the server decides what follows (and where to go if this
    // was the active tab).
    if (tab.dataset.closeUrl) {
      this.submit(tab.dataset.closeUrl, 'delete');
      return;
    }

    const tabs = this.tabTargets;
    const index = tabs.indexOf(tab);
    const wasActive = tab.dataset.state === 'active';
    tab.remove();
    this.sync();

    const remaining = this.tabTargets;
    const next = remaining[Math.min(index, remaining.length - 1)];
    if (wasActive && next) {
      if (this.isLink(next)) {
        this.triggerOf(next)?.click();
      } else if (this.emit('select', next)) {
        this.activate(next);
      }
    }
    if (this.returnFocusValue) this.restoreFocus();
    else this.triggerOf(this.activeTab() ?? next ?? remaining[0]!)?.focus();
  }

  // ── State ──────────────────────────────────────────────────────────────

  private activate(tab: HTMLElement) {
    for (const t of this.tabTargets) {
      const active = t === tab;
      t.dataset.state = active ? 'active' : 'inactive';
      this.triggerOf(t)?.setAttribute('aria-selected', active ? 'true' : 'false');
    }
    this.sync();
    tab.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  }

  // Re-derives everything that depends on position or count: roving
  // tabindex, Move left/right on the ends, Close at the minimum.
  private sync() {
    const tabs = this.tabTargets;
    const closable = tabs.length > this.minTabsValue;
    const active = this.activeTab() ?? tabs[0];

    tabs.forEach((tab) => {
      const focusable = tab === active ? '0' : '-1';
      this.triggerOf(tab)?.setAttribute('tabindex', focusable);
      tab.querySelector(MENU_TRIGGER)?.setAttribute('tabindex', focusable);

      tab.querySelectorAll<HTMLElement>('[data-close-part]').forEach((el) => this.setHidden(el, !closable));
      const left = !this.movableNeighbour(tab, -1);
      const right = !this.movableNeighbour(tab, 1);
      tab.querySelectorAll<HTMLElement>('[data-move="left"]').forEach((el) => this.setHidden(el, left));
      tab.querySelectorAll<HTMLElement>('[data-move="right"]').forEach((el) => this.setHidden(el, right));
    });
  }

  // Hidden menu items are also disabled so UI::Menu's arrow keys skip them.
  private setHidden(el: HTMLElement, hidden: boolean) {
    el.hidden = hidden;
    if (el.getAttribute('data-ui--menu-target') !== 'item') return;
    if (hidden) {
      el.setAttribute('disabled', '');
      el.setAttribute('data-disabled', 'true');
    } else {
      el.removeAttribute('disabled');
      el.removeAttribute('data-disabled');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  private emit(action: string, tab: HTMLElement | null, extra: Record<string, unknown> = {}) {
    const key = `${action}Url`;
    const detail = {
      value: tab?.dataset.value ?? null,
      url: tab ? (tab.dataset[key] ?? null) : null,
      ...extra,
    };
    const event = this.dispatch(action, { target: tab ?? this.element, detail, cancelable: true });
    return !event.defaultPrevented;
  }

  private submit(url: string, method: 'post' | 'patch' | 'delete', params: Record<string, string> = {}) {
    const form = document.createElement('form');
    form.method = 'post';
    form.action = url;
    form.hidden = true;

    const fields: Record<string, string> = { ...params };
    if (method !== 'post') fields._method = method;
    const csrfParam = document.querySelector<HTMLMetaElement>('meta[name="csrf-param"]')?.content;
    const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content;
    if (csrfParam && csrfToken) fields[csrfParam] = csrfToken;

    for (const [name, value] of Object.entries(fields)) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = name;
      input.value = value;
      form.appendChild(input);
    }

    form.addEventListener('turbo:submit-end', () => form.remove());
    this.element.appendChild(form);
    form.requestSubmit();
  }

  private fromMenu(event: Event): HTMLElement | null {
    event.preventDefault();
    const tab = this.tabFor(event.currentTarget);
    if (tab) this.menuOf(tab)?.close();
    return tab;
  }

  private tabFor(el: EventTarget | null): HTMLElement | null {
    const tab = (el as Element | null)?.closest<HTMLElement>(TAB) ?? null;
    return tab && this.tabTargets.includes(tab) ? tab : null;
  }

  private triggerOf(tab: HTMLElement) {
    return tab.querySelector<HTMLElement>(TRIGGER);
  }

  private isLink(tab: HTMLElement) {
    return this.triggerOf(tab)?.tagName === 'A';
  }

  private activeTab() {
    return this.tabTargets.find((t) => t.dataset.state === 'active');
  }

  private menuOf(tab: HTMLElement): MenuController | null {
    const el = tab.querySelector<HTMLElement>('[data-controller~="ui--menu"]');
    if (!el) return null;
    return this.application.getControllerForElementAndIdentifier(el, 'ui--menu') as MenuController | null;
  }

  private dialog(): DialogController | null {
    return this.application.getControllerForElementAndIdentifier(
      this.dialogTarget,
      'ui--dialog',
    ) as DialogController | null;
  }

  private restoreFocus() {
    const selector = this.returnFocusValue;
    if (!selector) return;
    requestAnimationFrame(() => document.querySelector<HTMLElement>(selector)?.focus());
  }
}
