import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--carousel"
//
// The strip scrolls by itself (scroll-snap); this only moves it a page at a
// time from the buttons, and shows each button while there's more that way.
// With indicators, it shows one for each place the strip can stop, lights the
// one in view, and scrolls to an indicator's card.
const EDGE = 2;

export default class extends Controller<HTMLElement> {
  static targets = ['track', 'previous', 'next', 'indicator'];

  declare readonly trackTarget: HTMLElement;
  declare readonly previousTarget: HTMLButtonElement;
  declare readonly nextTarget: HTMLButtonElement;
  declare readonly indicatorTargets: HTMLButtonElement[];

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
      if (this.indicatorTargets.length) this.light(scrolled);
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

  // An indicator for each place the strip can stop, and none when it can't scroll.
  // Between two stops, the one it's leaving empties as the one it's nearing
  // fills, in step with the scroll, so the pill slides with a finger rather
  // than jumping halfway. The current one is the fuller of the two.
  private light(scrolled: number) {
    const stops = this.stops();
    const shown = this.indicatorTargets.flatMap((_, index) =>
      index === 0 || stops[index] - stops[index - 1] > EDGE ? [index] : [],
    );
    const fills = this.indicatorTargets.map(() => 0);
    const after = shown.findIndex((index) => stops[index] > scrolled);
    if (after <= 0) {
      fills[shown[after === 0 ? 0 : shown.length - 1]] = 1;
    } else {
      const from = shown[after - 1];
      const to = shown[after];
      const progress = (scrolled - stops[from]) / (stops[to] - stops[from]);
      fills[from] = 1 - progress;
      fills[to] = progress;
    }
    const lit = fills.indexOf(Math.max(...fills));
    const scrolls = shown.length > 1;

    this.indicatorTargets.forEach((indicator, index) => {
      const hidden = !scrolls || !shown.includes(index);
      if (hidden && scrolls && document.activeElement === indicator) this.indicatorTargets[lit].focus();
      indicator.hidden = hidden;
      indicator.style.setProperty('--fill', fills[index].toFixed(3));
      if (index === lit) indicator.setAttribute('aria-current', 'true');
      else indicator.removeAttribute('aria-current');
    });
  }

  // A button that hides under the keyboard would drop focus to the page.
  private show(button: HTMLButtonElement, other: HTMLButtonElement, shown: boolean) {
    if (!shown && document.activeElement === button) other.focus();
    button.hidden = !shown;
  }
}
