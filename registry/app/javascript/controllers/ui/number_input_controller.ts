import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--number-input"
//
// The stepping itself is the browser's: stepUp() and stepDown() already respect
// min, max and step, and don't drift on decimals. This adds holding a button to
// keep counting, and turns a button off at its limit.
const HOLD_DELAY = 400;
const REPEAT_EVERY = 100;

type Direction = 'up' | 'down';
type StepEvent<E extends Event> = E & { params: { direction: Direction } };

export default class extends Controller<HTMLElement> {
  static targets = ['input', 'decrement', 'increment'];

  declare readonly inputTarget: HTMLInputElement;
  declare readonly decrementTarget: HTMLButtonElement;
  declare readonly incrementTarget: HTMLButtonElement;

  private holdTimer?: number;
  private repeatTimer?: number;
  private changed = false;

  connect() {
    this.sync();
  }

  disconnect() {
    this.release();
  }

  // One step at once, then repeating until the button is let go. Listens on the
  // window: a button that reaches its limit is disabled, and a disabled button
  // doesn't hear the pointer come up.
  press(event: StepEvent<PointerEvent>) {
    if (event.button !== 0) return;

    this.release();
    const { direction } = event.params;
    if (!this.step(direction)) return;

    window.addEventListener('pointerup', this.release);
    window.addEventListener('pointercancel', this.release);
    window.addEventListener('blur', this.release);
    this.holdTimer = window.setTimeout(() => {
      this.repeatTimer = window.setInterval(() => {
        if (!this.step(direction)) this.stopRepeating();
      }, REPEAT_EVERY);
    }, HOLD_DELAY);
  }

  // A pointer has already stepped in press(). A click with no pointer behind it
  // (detail 0) is the keyboard or a screen reader.
  click(event: StepEvent<MouseEvent>) {
    if (event.detail !== 0) return;

    if (this.step(event.params.direction)) this.release();
  }

  sync() {
    const input = this.inputTarget;
    const locked = input.disabled || input.readOnly;
    const value = input.valueAsNumber;
    this.decrementTarget.disabled = locked || value <= parseFloat(input.min);
    this.incrementTarget.disabled = locked || value >= parseFloat(input.max);
  }

  private release = () => {
    this.stopRepeating();
    window.removeEventListener('pointerup', this.release);
    window.removeEventListener('pointercancel', this.release);
    window.removeEventListener('blur', this.release);
    if (!this.changed) return;

    this.changed = false;
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }));
  };

  private stopRepeating() {
    window.clearTimeout(this.holdTimer);
    window.clearInterval(this.repeatTimer);
  }

  private step(direction: Direction): boolean {
    const input = this.inputTarget;
    const before = input.value;

    if (input.step === 'any') {
      this.stepByOne(direction);
    } else if (direction === 'up') {
      input.stepUp();
    } else {
      input.stepDown();
    }
    if (input.value === before) return false;

    this.changed = true;
    input.dispatchEvent(new Event('input', { bubbles: true }));
    return true;
  }

  // stepUp() throws on step="any", and limits are then up to us.
  private stepByOne(direction: Direction) {
    const input = this.inputTarget;
    const next = (input.valueAsNumber || 0) + (direction === 'up' ? 1 : -1);
    const min = parseFloat(input.min);
    const max = parseFloat(input.max);
    input.value = String(Math.min(Number.isNaN(max) ? next : max, Math.max(Number.isNaN(min) ? next : min, next)));
  }
}
