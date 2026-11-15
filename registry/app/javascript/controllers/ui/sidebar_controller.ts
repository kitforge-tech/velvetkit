import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--sidebar", on UI::Sidebar::Wrapper.
//
// On a wide screen the trigger collapses the sidebar, to its icons or out of
// sight as `collapsible:` says, and the choice goes in a cookie so the server
// draws the next page the same way. On a phone the sidebar is a drawer: the
// trigger opens it over the page, and Escape, the backdrop or a link close it.
const MOBILE = '(max-width: 767.98px)';
const YEAR = 60 * 60 * 24 * 365;
const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])';

export default class extends Controller<HTMLElement> {
  static targets = ['sidebar', 'container', 'trigger'];

  declare readonly hasSidebarTarget: boolean;
  declare readonly sidebarTarget: HTMLElement;
  declare readonly containerTarget: HTMLElement;
  declare readonly triggerTargets: HTMLElement[];

  private media = window.matchMedia(MOBILE);
  private opener: HTMLElement | null = null;

  connect() {
    this.media.addEventListener('change', this.resized);
    this.element.addEventListener('keydown', this.escape);
    document.addEventListener('turbo:before-cache', this.close);
    this.resized();
  }

  disconnect() {
    this.media.removeEventListener('change', this.resized);
    this.element.removeEventListener('keydown', this.escape);
    document.removeEventListener('turbo:before-cache', this.close);
    document.documentElement.style.removeProperty('overflow');
  }

  toggle(event?: Event) {
    if (!this.hasSidebarTarget) return;

    if (this.mobile) {
      if (this.drawerOpen) this.close();
      else this.open(event?.currentTarget as HTMLElement | undefined);
      return;
    }
    if (this.mode === 'none') return;

    this.setState(this.state === 'collapsed' ? 'expanded' : 'collapsed');
  }

  open(opener?: HTMLElement) {
    this.opener = opener ?? (document.activeElement as HTMLElement | null);
    this.sidebarTarget.dataset.mobile = 'open';
    document.documentElement.style.overflow = 'hidden';
    this.syncTriggers();
    // The current page's link, or else the first thing to focus.
    const first = this.containerTarget.querySelector<HTMLElement>('a[aria-current]') ?? this.containerTarget.querySelector<HTMLElement>(FOCUSABLE);
    // Hidden until the slide's first frame is drawn, and focus can't land on
    // what's hidden, so it waits a frame more.
    requestAnimationFrame(() => requestAnimationFrame(() => first?.focus({ preventScroll: true })));
  }

  close = () => {
    if (!this.hasSidebarTarget || !this.drawerOpen) return;

    delete this.sidebarTarget.dataset.mobile;
    document.documentElement.style.removeProperty('overflow');
    this.syncTriggers();
    if (this.containerTarget.contains(document.activeElement)) this.opener?.focus({ preventScroll: true });
    this.opener = null;
  };

  // A link followed in the drawer closes it, so the next page isn't under it.
  navigate(event: Event) {
    if (this.mobile && (event.target as Element).closest('a[href]')) this.close();
  }

  // Opens or closes a group of links under a menu item.
  toggleSub(event: Event) {
    const button = event.currentTarget as HTMLElement;
    const sub = document.getElementById(button.getAttribute('aria-controls') ?? '');
    if (!sub) return;

    const open = button.getAttribute('aria-expanded') !== 'true';
    button.setAttribute('aria-expanded', String(open));
    sub.hidden = !open;
  }

  private escape = (event: KeyboardEvent) => {
    if (event.key === 'Escape' && this.drawerOpen) {
      event.preventDefault();
      this.close();
    }
  };

  // Icons alone would leave the drawer unreadable, so on a phone the sidebar
  // shows in full whatever was chosen on a wide screen.
  private resized = () => {
    if (!this.hasSidebarTarget) return;

    if (!this.mobile) this.close();
    this.sidebarTarget.dataset.collapsible = !this.mobile && this.state === 'collapsed' ? this.mode : '';
    this.syncTriggers();
  };

  private setState(state: 'expanded' | 'collapsed') {
    this.sidebarTarget.dataset.state = state;
    this.sidebarTarget.dataset.collapsible = state === 'collapsed' ? this.mode : '';
    const name = this.sidebarTarget.dataset.cookie;
    if (name) document.cookie = `${name}=${state}; path=/; max-age=${YEAR}; samesite=lax`;
    this.syncTriggers();
  }

  private syncTriggers() {
    const expanded = this.mobile ? this.drawerOpen : this.state !== 'collapsed';
    this.triggerTargets.forEach((trigger) => trigger.setAttribute('aria-expanded', String(expanded)));
  }

  private get state() {
    return this.sidebarTarget.dataset.state === 'collapsed' ? 'collapsed' : 'expanded';
  }

  private get mode() {
    return this.sidebarTarget.dataset.collapsibleMode ?? 'icon';
  }

  private get mobile() {
    return this.media.matches;
  }

  private get drawerOpen() {
    return this.sidebarTarget.dataset.mobile === 'open';
  }
}
