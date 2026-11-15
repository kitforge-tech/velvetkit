import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--carousel"
//
// The strip scrolls by itself (scroll-snap); this only moves it a page at a
// time from the buttons, and shows each button while there's more that way.
const EDGE = 2;

export default class extends Controller<HTMLElement> {
  static targets = ['track', 'previous', 'next'];

  declare readonly trackTarget: HTMLElement;
  declare readonly previousTarget: HTMLButtonElement;
  declare readonly nextTarget: HTMLButtonElement;

  private frame?: number;
  private observer?: ResizeObserver;

  connect() {
    this.observer = new ResizeObserver(() => this.update());
    this.observer.observe(this.trackTarget);
    this.update();
  }

  disconnect() {
    this.observer?.disconnect();
    if (this.frame) cancelAnimationFrame(this.frame);
  }

  previous() {
    this.page(-1);
  }

  next() {
    this.page(1);
  }

  update() {
    if (this.frame) return;

    this.frame = requestAnimationFrame(() => {
      this.frame = undefined;
      const track = this.trackTarget;
      // scrollLeft runs negative in a right-to-left page.
      const scrolled = Math.abs(track.scrollLeft);
      this.show(this.previousTarget, this.nextTarget, scrolled > EDGE);
      this.show(this.nextTarget, this.previousTarget, scrolled + track.clientWidth < track.scrollWidth - EDGE);
    });
  }

  // Most of a strip's width, so the last card in view is the first one after.
  private page(direction: number) {
    const track = this.trackTarget;
    const forward = getComputedStyle(track).direction === 'rtl' ? -1 : 1;
    track.scrollBy({ left: direction * forward * track.clientWidth * 0.85 });
  }

  // A button that hides under the keyboard would drop focus to the page.
  private show(button: HTMLButtonElement, other: HTMLButtonElement, shown: boolean) {
    if (!shown && document.activeElement === button) other.focus();
    button.hidden = !shown;
  }
}
