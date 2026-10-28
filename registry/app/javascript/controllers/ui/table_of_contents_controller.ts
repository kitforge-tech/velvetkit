import { Controller } from '@hotwired/stimulus';

// Scrollspy: marks the link whose section was scrolled to last and slides the
// indicator beside it.
export default class extends Controller<HTMLElement> {
  static targets = ['link', 'indicator', 'rail'];
  static values = {
    offset: { type: Number, default: 80 },
    container: String,
  };

  declare readonly linkTargets: HTMLAnchorElement[];
  declare readonly indicatorTarget: HTMLElement;
  declare readonly railTarget: HTMLElement;
  declare offsetValue: number;
  declare containerValue: string;

  private scroller: HTMLElement | Window = window;
  private active: HTMLAnchorElement | null = null;
  private frame = 0;
  private locked = false;
  private unlockTimer = 0;
  private resizeObserver?: ResizeObserver;

  connect() {
    this.scroller =
      (this.containerValue && document.querySelector<HTMLElement>(this.containerValue)) || window;
    this.scroller.addEventListener('scroll', this.schedule, { passive: true });
    this.scroller.addEventListener('scrollend', this.unlock);
    this.resizeObserver = new ResizeObserver(this.schedule);
    this.resizeObserver.observe(this.element);
    this.update();
  }

  disconnect() {
    this.scroller.removeEventListener('scroll', this.schedule);
    this.scroller.removeEventListener('scrollend', this.unlock);
    this.resizeObserver?.disconnect();
    cancelAnimationFrame(this.frame);
    clearTimeout(this.unlockTimer);
  }

  // A click scrolls the section to the offset line itself: left to the browser
  // (or Turbo), the jump scrolls every ancestor, the window included, and lands
  // wherever scroll-margin says rather than where the section counts as reached.
  // The link is marked at once and held while the scroll runs, so the
  // indicator doesn't stop at every section on the way.
  select(event: MouseEvent) {
    if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const link = event.currentTarget as HTMLAnchorElement;
    const target = this.targetOf(link);
    if (!target) return;

    event.preventDefault();
    this.scrollToTarget(target);
    if (this.scroller instanceof Window) history.replaceState(history.state, '', link.hash);
    // Keyboard focus continues from the section, as it would after a jump.
    if (!target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
    target.focus({ preventScroll: true });

    this.setActive(link);
    this.locked = true;
    clearTimeout(this.unlockTimer);
    // scrollend never fires when the section is already in place, and some
    // browsers don't send it at all.
    this.unlockTimer = window.setTimeout(this.unlock, 1000);
  }

  private unlock = () => {
    this.locked = false;
  };

  private schedule = () => {
    if (!this.frame) this.frame = requestAnimationFrame(this.update);
  };

  private update = () => {
    this.frame = 0;
    if (this.locked) {
      this.moveIndicator();
      return;
    }

    const sections = this.sections();
    if (sections.length === 0) return this.setActive(null);

    // The last section whose top has passed the line; the first until one has.
    // At the very bottom, the last section, which may be too short to reach it.
    const line = this.scrollerTop() + this.offsetValue;
    let current = sections[0];
    if (this.atBottom()) {
      current = sections[sections.length - 1];
    } else {
      for (const section of sections) {
        if (section.top <= line) current = section;
      }
    }
    this.setActive(current.link);
  };

  private targetOf(link: HTMLAnchorElement) {
    const id = decodeURIComponent(link.hash.slice(1));
    return id ? document.getElementById(id) : null;
  }

  private scrollToTarget(target: HTMLElement) {
    const behavior = matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth';
    const distance = target.getBoundingClientRect().top - this.scrollerTop() - this.offsetValue;
    this.scroller.scrollBy({ top: distance, behavior });
  }

  // Links paired with the sections they point at, in the order they appear.
  private sections() {
    return this.linkTargets
      .map((link) => {
        const target = this.targetOf(link);
        return target && target.getClientRects().length > 0
          ? { link, top: target.getBoundingClientRect().top }
          : null;
      })
      .filter((section): section is { link: HTMLAnchorElement; top: number } => section !== null)
      .sort((a, b) => a.top - b.top);
  }

  private scrollerTop() {
    return this.scroller instanceof Window ? 0 : this.scroller.getBoundingClientRect().top;
  }

  private atBottom() {
    const el = this.scroller instanceof Window ? document.documentElement : this.scroller;
    return el.scrollHeight > el.clientHeight && el.scrollTop + el.clientHeight >= el.scrollHeight - 2;
  }

  private setActive(link: HTMLAnchorElement | null) {
    if (link !== this.active) {
      this.active = link;
      const ancestors = link ? this.ancestorsOf(link) : [];
      this.linkTargets.forEach((l) => {
        l.dataset.state = l === link ? 'active' : ancestors.includes(l) ? 'ancestor' : 'inactive';
        if (l === link) l.setAttribute('aria-current', 'location');
        else l.removeAttribute('aria-current');
      });
      this.dispatch('change', { detail: { href: link?.getAttribute('href') ?? null } });
    }
    this.moveIndicator();
  }

  // Links of the items this link's item is nested in.
  private ancestorsOf(link: HTMLAnchorElement) {
    const links: HTMLAnchorElement[] = [];
    let item = link.closest('li')?.parentElement?.closest('li');
    while (item && this.element.contains(item)) {
      const parent = item.querySelector<HTMLAnchorElement>(':scope > a');
      if (parent) links.push(parent);
      item = item.parentElement?.closest('li');
    }
    return links;
  }

  private moveIndicator() {
    const indicator = this.indicatorTarget;
    if (!this.active) {
      indicator.dataset.state = 'hidden';
      return;
    }
    const link = this.active.getBoundingClientRect();
    const rail = this.railTarget.getBoundingClientRect();
    indicator.style.transform = `translateY(${link.top - rail.top}px)`;
    indicator.style.height = `${link.height}px`;
    indicator.dataset.state = 'visible';
  }
}
