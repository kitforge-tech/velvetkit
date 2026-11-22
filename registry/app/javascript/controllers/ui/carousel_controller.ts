import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--carousel"
//
// The strip scrolls by itself (scroll-snap); this only moves it a page at a
// time from the buttons, and shows each button while there's more that way.
// With dots, it shows one for each place the strip can stop, lights the one
// in view, and scrolls to a dot's card.
const EDGE = 2;

export default class extends Controller<HTMLElement> {
  static targets = ['track', 'previous', 'next', 'dot'];

  declare readonly trackTarget: HTMLElement;
  declare readonly previousTarget: HTMLButtonElement;
  declare readonly nextTarget: HTMLButtonElement;
  declare readonly dotTargets: HTMLButtonElement[];

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

  go({ params }: { params: { index: number } }) {
    const track = this.trackTarget;
    const forward = getComputedStyle(track).direction === 'rtl' ? -1 : 1;
    track.scrollTo({ left: forward * this.stops()[params.index] });
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
      if (this.dotTargets.length) this.light(scrolled);
    });
  }

  // Most of a strip's width, so the last card in view is the first one after.
  private page(direction: number) {
    const track = this.trackTarget;
    const forward = getComputedStyle(track).direction === 'rtl' ? -1 : 1;
    track.scrollBy({ left: direction * forward * track.clientWidth * 0.85 });
  }

  // How far the strip scrolls to bring each card to its start, held to the
  // end: the last few cards can't reach the start, so they share the end.
  private stops() {
    const track = this.trackTarget;
    const rtl = getComputedStyle(track).direction === 'rtl';
    const box = track.getBoundingClientRect();
    const scrolled = Math.abs(track.scrollLeft);
    const end = track.scrollWidth - track.clientWidth;
    const starts = Array.from(track.children, (item) => {
      const card = item.getBoundingClientRect();
      return (rtl ? box.right - card.right : card.left - box.left) + scrolled;
    });
    return starts.map((start) => Math.min(Math.max(start - starts[0], 0), end));
  }

  // A dot for each place the strip can stop, and none when it can't scroll.
  // The lit one is the stop nearest where it's scrolled to.
  private light(scrolled: number) {
    const stops = this.stops();
    const shown = this.dotTargets.map((_, index) => index === 0 || stops[index] - stops[index - 1] > EDGE);
    const scrolls = shown.filter(Boolean).length > 1;
    let lit = 0;
    stops.forEach((stop, index) => {
      if (shown[index] && Math.abs(stop - scrolled) < Math.abs(stops[lit] - scrolled)) lit = index;
    });

    this.dotTargets.forEach((dot, index) => {
      const hidden = !scrolls || !shown[index];
      if (hidden && scrolls && document.activeElement === dot) this.dotTargets[lit].focus();
      dot.hidden = hidden;
      if (index === lit) dot.setAttribute('aria-current', 'true');
      else dot.removeAttribute('aria-current');
    });
  }

  // A button that hides under the keyboard would drop focus to the page.
  private show(button: HTMLButtonElement, other: HTMLButtonElement, shown: boolean) {
    if (!shown && document.activeElement === button) other.focus();
    button.hidden = !shown;
  }
}
