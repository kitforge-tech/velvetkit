import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--slider"
//
// The handles are native range inputs, which do the keyboard, the form and
// the screen reader. This draws the filled part of the track, keeps the shown
// value and aria-valuetext current, and takes the pointer: a press anywhere on
// the track grabs the nearest handle, so a range's two handles can be dragged
// even when they sit on top of each other, and they never pass.
type PickEvent = MouseEvent & { params: { value: number } };

export default class extends Controller<HTMLElement> {
  static targets = ['input', 'track', 'output'];
  static values = { format: String, rangeFormat: String, labels: Object };

  declare readonly inputTargets: HTMLInputElement[];
  declare readonly trackTarget: HTMLElement;
  declare readonly outputTarget: HTMLOutputElement;
  declare readonly hasOutputTarget: boolean;
  declare readonly formatValue: string;
  declare readonly rangeFormatValue: string;
  declare readonly labelsValue: Record<string, string>;

  private dragging?: HTMLInputElement;
  private pointerId?: number;
  private startX = 0;
  private before = '';

  connect() {
    this.element.closest('form')?.addEventListener('reset', this.afterReset);
    this.sync();
  }

  disconnect() {
    this.element.closest('form')?.removeEventListener('reset', this.afterReset);
    this.release();
  }

  // On every input: a range's handles can meet but not cross.
  sync(event?: Event) {
    const [low, high] = this.inputTargets;
    if (high) {
      if (event?.target === low && low.valueAsNumber > high.valueAsNumber) low.value = high.value;
      if (event?.target === high && high.valueAsNumber < low.valueAsNumber) high.value = low.value;
    }

    const from = high ? this.fraction(low) : 0;
    const to = this.fraction(high ?? low);
    this.element.style.setProperty('--from', String(from));
    this.element.style.setProperty('--to', String(to));
    for (const input of this.inputTargets) input.setAttribute('aria-valuetext', this.text(input.value));
    if (this.hasOutputTarget) {
      this.outputTarget.textContent = high
        ? this.rangeFormatValue.replace('%{from}', this.text(low.value)).replace('%{to}', this.text(high.value))
        : this.text(low.value);
    }
  }

  press(event: PointerEvent) {
    if (event.button !== 0 || this.inputTargets[0].disabled) return;

    event.preventDefault();
    const value = this.valueAt(event.clientX);
    this.dragging = this.nearest(value);
    this.startX = event.clientX;
    this.pointerId = event.pointerId;
    this.before = this.inputTargets.map((input) => input.value).join();
    this.trackTarget.setPointerCapture(event.pointerId);
    this.trackTarget.addEventListener('pointermove', this.move);
    this.trackTarget.addEventListener('pointerup', this.release);
    this.trackTarget.addEventListener('pointercancel', this.release);
    // Two handles on one spot: which one is decided by the way the pointer moves.
    if (this.dragging) this.moveTo(this.dragging, value);
  }

  // A mark: the nearest handle goes there, as if the track were pressed.
  pick(event: PickEvent) {
    const value = event.params.value;
    const input = this.nearest(value) ?? this.inputTargets[0];
    const before = input.value;
    this.moveTo(input, value);
    input.focus();
    if (input.value !== before) input.dispatchEvent(new Event('change', { bubbles: true }));
  }

  private move = (event: PointerEvent) => {
    const value = this.valueAt(event.clientX);
    if (!this.dragging) {
      if (Math.abs(event.clientX - this.startX) < 2) return;

      const [low, high] = this.inputTargets;
      this.dragging = (event.clientX < this.startX) !== this.rtl ? low : high;
    }
    this.moveTo(this.dragging, value);
  };

  private release = () => {
    const input = this.dragging;
    if (this.pointerId !== undefined && this.trackTarget.hasPointerCapture(this.pointerId)) {
      this.trackTarget.releasePointerCapture(this.pointerId);
    }
    this.trackTarget.removeEventListener('pointermove', this.move);
    this.trackTarget.removeEventListener('pointerup', this.release);
    this.trackTarget.removeEventListener('pointercancel', this.release);
    for (const each of this.inputTargets) delete each.dataset.active;
    this.dragging = undefined;
    this.pointerId = undefined;
    if (input && this.inputTargets.map((each) => each.value).join() !== this.before) {
      input.dispatchEvent(new Event('change', { bubbles: true }));
    }
  };

  private afterReset = () => requestAnimationFrame(() => this.sync());

  // Sets the value the way the keyboard would, so step and the other handle
  // are respected, and fires input as the browser does.
  private moveTo(input: HTMLInputElement, value: number) {
    const [low, high] = this.inputTargets;
    let next = value;
    if (high && input === low) next = Math.min(next, high.valueAsNumber);
    if (high && input === high) next = Math.max(next, low.valueAsNumber);

    input.dataset.active = '';
    input.focus({ preventScroll: true });
    if (String(next) === input.value) return;

    input.value = String(next);
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }

  // The handle closest to a value; none when a range's two are equally close
  // and on one spot, until the pointer moves.
  private nearest(value: number): HTMLInputElement | undefined {
    const [low, high] = this.inputTargets;
    if (!high) return low;
    if (low.value === high.value) {
      if (value === low.valueAsNumber) return undefined;
      return value < low.valueAsNumber ? low : high;
    }

    return Math.abs(value - low.valueAsNumber) <= Math.abs(value - high.valueAsNumber) ? low : high;
  }

  // The value under a point on the track, snapped to step. The thumb's centre
  // can't reach the very ends, so neither does the scale.
  private valueAt(clientX: number): number {
    const input = this.inputTargets[0];
    const rect = this.trackTarget.getBoundingClientRect();
    const thumb = input.offsetHeight;
    let fraction = (clientX - rect.left - thumb / 2) / Math.max(1, rect.width - thumb);
    fraction = Math.min(1, Math.max(0, fraction));
    if (this.rtl) fraction = 1 - fraction;

    const { min, max, step } = this.bounds(input);
    const steps = Math.round((fraction * (max - min)) / step);
    return Number(Math.min(max, min + steps * step).toFixed(this.decimals(step)));
  }

  private fraction(input: HTMLInputElement): number {
    const { min, max } = this.bounds(input);
    return max === min ? 0 : (input.valueAsNumber - min) / (max - min);
  }

  private bounds(input: HTMLInputElement) {
    const min = parseFloat(input.min) || 0;
    const max = Number.isNaN(parseFloat(input.max)) ? 100 : parseFloat(input.max);
    const step = parseFloat(input.step) || 1;
    return { min, max, step };
  }

  // Matches the server's: the value as the step writes it, "3" not "3.0".
  private text(value: string): string {
    const number = String(Number(Number(value).toFixed(this.decimals(this.bounds(this.inputTargets[0]).step))));
    return this.labelsValue[number] ?? this.formatValue.replace('%{value}', number);
  }

  private decimals(step: number): number {
    return (String(step).split('.')[1] ?? '').length;
  }

  private get rtl(): boolean {
    return getComputedStyle(this.element).direction === 'rtl';
  }
}
