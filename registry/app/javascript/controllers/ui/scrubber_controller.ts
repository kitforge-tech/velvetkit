import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--scrubber"
//
// Places each mark as far down the rail as its heading is down the list, moves
// the line with the scroll, and scrolls the list while the rail is dragged.
// The rail stands for the whole scroll, top to bottom, like a scrollbar.
const LABEL_GAP = 18;

export default class extends Controller<HTMLElement> {
  static targets = ['rail', 'mark', 'thumb', 'tip'];
  static values = { for: String };

  declare readonly railTarget: HTMLElement;
  declare readonly markTargets: HTMLAnchorElement[];
  declare readonly thumbTarget: HTMLElement;
  declare readonly tipTarget: HTMLElement;
  declare readonly forValue: string;

  private scroller: HTMLElement | null = null;
  private positions: number[] = [];
  private dragging: number | null = null;
  private frame?: number;
  private observer?: ResizeObserver;

  connect() {
    this.scroller = this.forValue ? document.getElementById(this.forValue) : null;
    this.scrollEvents.addEventListener('scroll', this.scrolled, { passive: true });
    this.observer = new ResizeObserver(() => this.layout());
    this.observer.observe(this.content);
    this.observer.observe(this.railTarget);
    this.layout();
  }

  disconnect() {
    this.scrollEvents.removeEventListener('scroll', this.scrolled);
    this.observer?.disconnect();
    if (this.frame) cancelAnimationFrame(this.frame);
  }

  // Where each heading falls in the scroll, as a share of it. Labels too close
  // to the one above are left as dots, so they don't overlap.
  layout() {
    const height = this.railTarget.clientHeight;
    const max = this.maxScroll;
    let lastLabel = -Infinity;
    this.positions = this.markTargets.map((mark) => {
      const heading = this.headingFor(mark);
      const share = heading && max > 0 ? Math.min(1, Math.max(0, this.offsetOf(heading) / max)) : 0;
      const y = share * height;
      mark.style.transform = `translateY(${y}px) translateY(-50%)`;
      if (mark.dataset.major === 'true') {
        const crowded = y - lastLabel < LABEL_GAP;
        mark.classList.toggle('text-transparent', crowded);
        if (!crowded) lastLabel = y;
      }
      return share;
    });
    this.element.toggleAttribute('data-ready', true);
    this.place();
  }

  grab(event: PointerEvent) {
    if (event.button !== 0) return;

    event.preventDefault();
    this.dragging = event.pointerId;
    this.railTarget.setPointerCapture(event.pointerId);
    this.scrubTo(event);
  }

  point(event: PointerEvent) {
    if (this.dragging === event.pointerId) this.scrubTo(event);
    else if (event.pointerType === 'mouse') this.showTip(this.shareAt(event), true);
  }

  release(event: PointerEvent) {
    if (this.dragging !== event.pointerId) return;

    this.dragging = null;
    if (this.railTarget.hasPointerCapture(event.pointerId)) this.railTarget.releasePointerCapture(event.pointerId);
    this.hideTip();
  }

  leave() {
    if (this.dragging === null) this.hideTip();
  }

  // One stop on the keyboard: the arrows move between the marks.
  keydown(event: KeyboardEvent) {
    const marks = this.markTargets;
    const current = marks.indexOf(document.activeElement as HTMLAnchorElement);
    if (current < 0) return;

    const next = { ArrowDown: current + 1, ArrowUp: current - 1, Home: 0, End: marks.length - 1 }[event.key];
    if (next === undefined) return;

    event.preventDefault();
    const index = Math.min(marks.length - 1, Math.max(0, next));
    marks.forEach((mark, i) => (mark.tabIndex = i === index ? 0 : -1));
    marks[index].focus();
    this.showTip(this.positions[index] ?? 0, false, marks[index].dataset.label);
  }

  private scrolled = () => {
    if (this.frame) return;
    this.frame = requestAnimationFrame(() => {
      this.frame = undefined;
      this.place();
    });
  };

  // The line, and the mark for where the list is now as the one Tab lands on.
  private place() {
    const max = this.maxScroll;
    const share = max > 0 ? this.scrollTop / max : 0;
    this.thumbTarget.style.transform = `translateY(${share * this.railTarget.clientHeight}px) translateY(-50%)`;
    if (this.markTargets.some((mark) => mark === document.activeElement)) return;

    const index = this.indexAt(share);
    this.markTargets.forEach((mark, i) => (mark.tabIndex = i === index ? 0 : -1));
  }

  private scrubTo(event: PointerEvent) {
    const share = this.shareAt(event);
    const top = share * this.maxScroll;
    if (this.scroller) this.scroller.scrollTo({ top });
    else window.scrollTo({ top });
    this.showTip(share, true);
  }

  private showTip(share: number, atPointer: boolean, text?: string) {
    const label = text ?? this.markTargets[this.indexAt(share)]?.dataset.label ?? '';
    if (!label) return;

    this.tipTarget.textContent = label;
    this.tipTarget.style.transform = `translateY(${share * this.railTarget.clientHeight}px) translateY(-50%)`;
    this.tipTarget.toggleAttribute('data-shown', true);
    this.tipTarget.dataset.pointer = String(atPointer);
  }

  private hideTip() {
    this.tipTarget.removeAttribute('data-shown');
  }

  // The last mark at or above this point of the scroll.
  private indexAt(share: number): number {
    let index = 0;
    this.positions.forEach((position, i) => {
      if (position <= share + 0.001) index = i;
    });
    return index;
  }

  private shareAt(event: PointerEvent): number {
    const rect = this.railTarget.getBoundingClientRect();
    return Math.min(1, Math.max(0, (event.clientY - rect.top) / rect.height));
  }

  private headingFor(mark: HTMLAnchorElement): HTMLElement | null {
    const id = decodeURIComponent(mark.hash.slice(1));
    return id ? document.getElementById(id) : null;
  }

  // How far down the scroll a heading is, measured from what's on screen.
  private offsetOf(element: HTMLElement): number {
    const top = element.getBoundingClientRect().top;
    if (this.scroller) return top - this.scroller.getBoundingClientRect().top + this.scroller.scrollTop;
    return top + window.scrollY;
  }

  private get maxScroll(): number {
    if (this.scroller) return this.scroller.scrollHeight - this.scroller.clientHeight;
    return document.documentElement.scrollHeight - window.innerHeight;
  }

  private get scrollTop(): number {
    return this.scroller ? this.scroller.scrollTop : window.scrollY;
  }

  private get scrollEvents(): HTMLElement | Window {
    return this.scroller ?? window;
  }

  private get content(): Element {
    return this.scroller?.firstElementChild ?? document.body;
  }
}
