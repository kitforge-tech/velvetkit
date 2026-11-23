import { Controller } from '@hotwired/stimulus';

// A file tree after the WAI-ARIA tree pattern: one row in the tab order, the
// arrow keys to move and to open and close folders, a letter to jump to a name.
// Picking a file that isn't a link selects it and dispatches
// `ui--file-tree:select` with `{ value, name }`.

// The curve iOS sheets and drawers settle on: quick to start, a long soft
// landing.
const EASING = 'cubic-bezier(0.32, 0.72, 0, 1)';
const OPEN_MS = 380;
const CLOSE_MS = 300;

export default class extends Controller<HTMLElement> {
  static targets = ['item'];

  declare readonly itemTargets: HTMLElement[];

  private animations = new Map<HTMLElement, Animation>();
  private reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

  disconnect() {
    this.animations.forEach((animation) => animation.finish());
  }

  connect() {
    const visible = this.visibleItems();
    const start = visible.find((item) => item.getAttribute('aria-selected') === 'true') ?? visible[0];
    if (start) this.makeTabbable(start);
  }

  click(event: MouseEvent) {
    const item = this.itemFor(event.target);
    if (!item) return;
    this.makeTabbable(item);
    if (this.isFolder(item)) this.setOpen(item, !this.isOpen(item));
    else this.select(item);
  }

  keydown(event: KeyboardEvent) {
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    const item = this.itemFor(event.target);
    if (!item) return;
    const visible = this.visibleItems();
    const index = visible.indexOf(item);
    const rtl = getComputedStyle(this.element).direction === 'rtl';
    const key = rtl && event.key === 'ArrowLeft' ? 'ArrowRight' : rtl && event.key === 'ArrowRight' ? 'ArrowLeft' : event.key;
    let next: HTMLElement | null | undefined;

    switch (key) {
      case 'ArrowDown':
        next = visible[index + 1];
        break;
      case 'ArrowUp':
        next = visible[index - 1];
        break;
      case 'Home':
        next = visible[0];
        break;
      case 'End':
        next = visible[visible.length - 1];
        break;
      case 'ArrowRight':
        if (!this.isFolder(item)) break;
        if (this.isOpen(item)) next = this.childrenOf(item)[0];
        else this.setOpen(item, true);
        break;
      case 'ArrowLeft':
        if (this.isFolder(item) && this.isOpen(item)) this.setOpen(item, false);
        else next = this.parentOf(item);
        break;
      case 'Enter':
      case ' ':
        // Enter on a link follows it, and the click that makes marks it.
        if (key === 'Enter' && item instanceof HTMLAnchorElement) return;
        item.click();
        break;
      default:
        if (key.length !== 1 || key === ' ') return;
        next = this.startingWith(visible, index, key);
        if (!next) return;
    }

    event.preventDefault();
    if (next) {
      this.makeTabbable(next);
      next.focus();
    }
  }

  private itemFor(target: EventTarget | null): HTMLElement | null {
    const item = (target as Element | null)?.closest<HTMLElement>('[role="treeitem"]');
    return item && this.itemTargets.includes(item) ? item : null;
  }

  // A closing group is still drawn until its animation ends, but its rows are
  // already out of reach of the keyboard.
  private visibleItems(): HTMLElement[] {
    return this.itemTargets.filter((item) => !item.closest('[role="group"][data-state="closed"]'));
  }

  private isFolder(item: HTMLElement) {
    return item.hasAttribute('aria-expanded');
  }

  private isOpen(item: HTMLElement) {
    return item.getAttribute('aria-expanded') === 'true';
  }

  private groupOf(item: HTMLElement): HTMLElement | null {
    const id = item.getAttribute('aria-owns');
    return id ? document.getElementById(id) : null;
  }

  private setOpen(item: HTMLElement, open: boolean) {
    item.setAttribute('aria-expanded', String(open));
    const group = this.groupOf(item);
    if (!group) return;
    group.dataset.state = open ? 'open' : 'closed';
    this.animate(group, open);
  }

  // Grows or shrinks the group between nothing and its full height while its
  // rows fade and settle into place. Clicked again part way, it turns round
  // from wherever it has got to rather than starting over.
  private animate(group: HTMLElement, open: boolean) {
    const running = this.animations.get(group);
    const from = group.hidden ? 0 : group.getBoundingClientRect().height;
    const opacity = group.hidden ? 0 : Number(getComputedStyle(group).opacity);
    running?.cancel();
    group.hidden = false;
    group.inert = !open;

    if (this.reducedMotion.matches) {
      group.hidden = !open;
      return;
    }

    const to = open ? group.scrollHeight : 0;
    const animation = group.animate(
      [
        { height: `${from}px`, opacity, transform: `translateY(${open && !running ? -6 : 0}px)` },
        { height: `${to}px`, opacity: open ? 1 : 0, transform: `translateY(${open ? 0 : -4}px)` },
      ],
      { duration: open ? OPEN_MS : CLOSE_MS, easing: EASING },
    );
    group.style.overflow = 'hidden';
    this.animations.set(group, animation);

    animation.onfinish = () => {
      this.animations.delete(group);
      group.style.overflow = '';
      group.inert = false;
      if (!open) group.hidden = true;
    };
  }

  private childrenOf(item: HTMLElement): HTMLElement[] {
    const group = this.groupOf(item);
    return group ? Array.from(group.querySelectorAll<HTMLElement>(':scope > li > [role="treeitem"]')) : [];
  }

  private parentOf(item: HTMLElement): HTMLElement | null {
    const group = item.closest<HTMLElement>('[role="group"]');
    return group?.parentElement?.querySelector<HTMLElement>(':scope > [role="treeitem"]') ?? null;
  }

  // The next visible row, after this one and round to the top, whose name
  // starts with the letter typed.
  private startingWith(visible: HTMLElement[], index: number, letter: string) {
    const wanted = letter.toLocaleLowerCase();
    for (let step = 1; step <= visible.length; step++) {
      const candidate = visible[(index + step) % visible.length];
      if (candidate?.dataset.name?.toLocaleLowerCase().startsWith(wanted)) return candidate;
    }
    return undefined;
  }

  private makeTabbable(item: HTMLElement) {
    this.itemTargets.forEach((other) => (other.tabIndex = other === item ? 0 : -1));
  }

  private select(item: HTMLElement) {
    this.itemTargets.forEach((other) => {
      if (other.hasAttribute('aria-selected')) other.setAttribute('aria-selected', String(other === item));
    });
    this.dispatch('select', { detail: { value: item.dataset.value ?? '', name: item.dataset.name ?? '' } });
  }
}
