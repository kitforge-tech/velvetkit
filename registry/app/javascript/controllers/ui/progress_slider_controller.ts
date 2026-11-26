import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--progress-slider"
//
// The input is a native range input, which does the keyboard, the form and
// the screen reader, and can't be seen. This takes the pointer: a press on the
// bar jumps there and drags, and while it's held the root has data-dragging,
// which squeezes the bar (the CSS does that). While dragged, the fill follows
// the pointer freely and the value keeps to the step; the bubble leans against
// the drag, harder the faster it goes, and the bar stretches after a pointer
// pulled past an end. The caption under the bar rolls to each new value.
//
// One pointer at a time: a second finger is ignored. A finger only drags once
// it moves sideways, so a swipe that starts on the bar can still scroll the
// page (the browser then cancels the pointer, and the value goes back); a tap
// jumps to where it lands. Once it's dragging, the page stays put however the
// finger wanders.
const MAX_TILT = 14; // degrees
const TILT_PER_SPEED = 30; // degrees per pixel a millisecond
const MAX_STRETCH = 0.085; // a share of the bar's width, never quite reached
const STRETCH_PX = 60; // pulled this far past the end, it's half way there
const SETTLE_AFTER = 90; // ms without moving before the bubble stands up
const TOUCH_SLOP = 6; // px a finger moves sideways before it drags
const TAP_PRESS = 140; // ms a tap holds the bar squeezed

export default class extends Controller<HTMLElement> {
  static targets = ['input', 'track', 'bubble', 'output'];
  static values = { format: String, labels: Object };

  declare readonly inputTarget: HTMLInputElement;
  declare readonly trackTarget: HTMLElement;
  declare readonly bubbleTarget: HTMLElement;
  declare readonly hasBubbleTarget: boolean;
  declare readonly outputTarget: HTMLOutputElement;
  declare readonly hasOutputTarget: boolean;
  declare readonly formatValue: string;
  declare readonly labelsValue: Record<string, string>;

  private pointerId?: number;
  // False while a finger is down but hasn't yet moved sideways.
  private moving = false;
  private before = '';
  private shown = '';
  private shownValue = 0;
  private startX = 0;
  private startY = 0;
  private lastX = 0;
  private lastTime = 0;
  private settle?: number;
  private tapPress?: number;
  private ghost?: HTMLElement;
  // Where the pointer is along the bar, 0 to 1, while it's held: the fill
  // follows this rather than the value, which keeps to the step.
  private held?: number;

  connect() {
    this.element.closest('form')?.addEventListener('reset', this.afterReset);
    // Not passive, so it can stop the page scrolling under a drag.
    this.trackTarget.addEventListener('touchmove', this.holdPage, { passive: false });
    // A page restored from Turbo's cache can hold a roll caught mid-way, or a
    // drag that was never let go.
    this.element.querySelectorAll('[data-ghost]').forEach((ghost) => ghost.remove());
    delete this.element.dataset.dragging;
    this.element.style.removeProperty('--tilt');
    this.element.style.removeProperty('--stretch');
    this.shown = this.text(this.inputTarget.value);
    this.shownValue = this.inputTarget.valueAsNumber;
    this.sync();
  }

  disconnect() {
    this.element.closest('form')?.removeEventListener('reset', this.afterReset);
    this.trackTarget.removeEventListener('touchmove', this.holdPage);
    this.release(false);
  }

  sync() {
    const input = this.inputTarget;
    const to = this.held ?? this.fraction();
    this.element.style.setProperty('--to', String(to));
    const { min, max } = this.bounds;
    this.element.toggleAttribute('data-at-max', max > min && input.valueAsNumber >= max);
    const text = this.text(input.value);
    input.setAttribute('aria-valuetext', text);
    if (this.hasBubbleTarget) this.bubbleTarget.textContent = text;
    if (text !== this.shown) this.roll(text, input.valueAsNumber > this.shownValue);
    this.shown = text;
    this.shownValue = input.valueAsNumber;
  }

  press(event: PointerEvent) {
    if (event.button !== 0 || this.inputTarget.disabled || this.pointerId !== undefined) return;

    event.preventDefault();
    this.pointerId = event.pointerId;
    this.before = this.inputTarget.value;
    this.startX = this.lastX = event.clientX;
    this.startY = event.clientY;
    this.lastTime = event.timeStamp;
    window.clearTimeout(this.tapPress);
    // A finger might be starting a scroll, so the bar waits to squeeze until
    // it's clearly a drag; anything else squeezes at once.
    this.moving = event.pointerType !== 'touch';
    if (this.moving) this.element.dataset.dragging = '';
    if (this.trackTarget.isConnected) this.trackTarget.setPointerCapture(event.pointerId);
    this.trackTarget.addEventListener('pointermove', this.move);
    this.trackTarget.addEventListener('pointerup', this.lift);
    this.trackTarget.addEventListener('pointercancel', this.cancel);
    this.trackTarget.addEventListener('lostpointercapture', this.lost);
    // Focused for the keyboard to carry on from, without the keyboard's look:
    // the bubble stays for keyboard focus only.
    this.inputTarget.focus({ preventScroll: true, focusVisible: false } as FocusOptions);
    if (this.moving) this.moveTo(event.clientX);
  }

  private move = (event: PointerEvent) => {
    if (event.pointerId !== this.pointerId) return;
    if (!this.moving) {
      const across = Math.abs(event.clientX - this.startX);
      if (across < TOUCH_SLOP || across < Math.abs(event.clientY - this.startY)) return;

      this.moving = true;
      this.element.dataset.dragging = '';
    }

    const elapsed = Math.max(1, event.timeStamp - this.lastTime);
    this.lean((event.clientX - this.lastX) / elapsed);
    this.lastX = event.clientX;
    this.lastTime = event.timeStamp;
    this.moveTo(event.clientX);
  };

  // touch-pan-y lets a finger scroll the page up and down, which is what a
  // swipe that only starts on the bar wants; once it's dragging, it mustn't.
  private holdPage = (event: TouchEvent) => {
    if (this.moving && this.pointerId !== undefined && event.cancelable) event.preventDefault();
  };

  // Let go: a tap that never moved jumps to where it landed, and the bar
  // squeezes for a moment, as a press would have.
  private lift = (event: PointerEvent) => {
    if (event.pointerId !== this.pointerId) return;
    const tap = !this.moving;
    if (tap) this.moveTo(event.clientX);
    this.release();
    if (!tap) return;

    this.element.dataset.dragging = '';
    this.tapPress = window.setTimeout(() => delete this.element.dataset.dragging, TAP_PRESS);
  };

  // The browser took the pointer, most often to scroll: as if it never happened.
  private cancel = (event: PointerEvent) => {
    if (event.pointerId !== this.pointerId) return;
    if (this.inputTarget.value !== this.before) {
      this.inputTarget.value = this.before;
      this.inputTarget.dispatchEvent(new Event('input', { bubbles: true }));
    }
    this.release(false);
  };

  // Capture gone without a pointerup (the track was moved in the page, a
  // dialog opened): keep where it got to.
  private lost = (event: PointerEvent) => {
    if (event.pointerId === this.pointerId) this.release();
  };

  private release(commit = true) {
    const track = this.trackTarget;
    track.removeEventListener('pointermove', this.move);
    track.removeEventListener('pointerup', this.lift);
    track.removeEventListener('pointercancel', this.cancel);
    track.removeEventListener('lostpointercapture', this.lost);
    if (this.pointerId !== undefined && track.hasPointerCapture(this.pointerId)) {
      track.releasePointerCapture(this.pointerId);
    }
    window.clearTimeout(this.settle);
    window.clearTimeout(this.tapPress);
    delete this.element.dataset.dragging;
    this.element.style.removeProperty('--tilt');
    this.element.style.removeProperty('--stretch');
    const wasHeld = this.pointerId !== undefined;
    this.pointerId = undefined;
    this.moving = false;
    this.held = undefined;
    // The fill glides from the pointer onto the value.
    this.sync();
    if (commit && wasHeld && this.inputTarget.value !== this.before) {
      this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  private afterReset = () => requestAnimationFrame(() => this.sync());

  // Sets the value the way the keyboard would, and fires input as the
  // browser does.
  private moveTo(clientX: number) {
    const rect = this.trackTarget.getBoundingClientRect();
    const past = clientX < rect.left ? clientX - rect.left : clientX > rect.right ? clientX - rect.right : 0;
    this.stretch(past);

    const across = Math.min(1, Math.max(0, (clientX - rect.left) / Math.max(1, rect.width)));
    this.held = this.rtl ? 1 - across : across;
    const next = String(this.valueOf(this.held));
    if (next === this.inputTarget.value) {
      this.sync();
      return;
    }

    this.inputTarget.value = next;
    this.inputTarget.dispatchEvent(new Event('input', { bubbles: true }));
  }

  // Leans against the drag, the way something carried swings back, then
  // stands up again once the pointer stops.
  private lean(speed: number) {
    if (this.reducedMotion) return;

    const tilt = Math.max(-MAX_TILT, Math.min(MAX_TILT, -speed * TILT_PER_SPEED));
    this.element.style.setProperty('--tilt', `${tilt.toFixed(1)}deg`);
    window.clearTimeout(this.settle);
    this.settle = window.setTimeout(() => this.element.style.removeProperty('--tilt'), SETTLE_AFTER);
  }

  // Past an end, the bar gives, less the further it's pulled, from the other
  // end (the CSS thins it as it stretches).
  private stretch(past: number) {
    if (past === 0 || this.reducedMotion) {
      this.element.style.removeProperty('--stretch');
      return;
    }

    const give = MAX_STRETCH * (1 - 1 / (Math.abs(past) / STRETCH_PX + 1));
    this.element.style.setProperty('--stretch', String(1 + give));
    this.element.style.setProperty('--stretch-origin', past > 0 ? 'left' : 'right');
  }

  // The old value slides out one way as the new one comes in from the other:
  // up for a bigger value, down for a smaller one. A quick drag through many
  // values only ever has the last one leaving.
  private roll(text: string, up: boolean) {
    if (!this.hasOutputTarget) return;

    const output = this.outputTarget;
    const old = output.textContent ?? '';
    output.textContent = text;
    this.ghost?.remove();
    this.ghost = undefined;
    if (this.reducedMotion || typeof output.animate !== 'function') return;

    const ghost = document.createElement('span');
    ghost.textContent = old;
    ghost.dataset.ghost = '';
    ghost.className = 'pointer-events-none absolute inset-x-0 top-0 truncate';
    output.parentElement?.appendChild(ghost);
    this.ghost = ghost;
    const timing = { duration: 220, easing: 'cubic-bezier(0.22, 1, 0.36, 1)' };
    ghost
      .animate([{ transform: 'none', opacity: 1 }, { transform: `translateY(${up ? '-100%' : '100%'})`, opacity: 0 }], timing)
      .finished.then(() => ghost.remove(), () => ghost.remove());
    output.getAnimations().forEach((animation) => animation.cancel());
    output.animate(
      [{ transform: `translateY(${up ? '100%' : '-100%'})`, opacity: 0 }, { transform: 'none', opacity: 1 }],
      timing,
    );
  }

  // The value at a fraction of the bar, snapped to step. A step that doesn't
  // divide the range stops short of max, as the browser does.
  private valueOf(fraction: number): number {
    const { min, max, step } = this.bounds;
    const last = Math.floor((max - min) / step + 1e-9);
    const steps = Math.min(last, Math.round((fraction * (max - min)) / step));
    return Number((min + steps * step).toFixed(this.decimals(step)));
  }

  private fraction(): number {
    const { min, max } = this.bounds;
    return max === min ? 0 : (this.inputTarget.valueAsNumber - min) / (max - min);
  }

  private get bounds() {
    const input = this.inputTarget;
    const min = parseFloat(input.min) || 0;
    const max = Number.isNaN(parseFloat(input.max)) ? 100 : parseFloat(input.max);
    const step = parseFloat(input.step) || 1;
    return { min, max, step };
  }

  // Matches the server's: the value as the step writes it, "3" not "3.0".
  private text(value: string): string {
    const number = String(Number(Number(value).toFixed(this.decimals(this.bounds.step))));
    return this.labelsValue[number] ?? this.formatValue.replaceAll('%{value}', number);
  }

  private decimals(step: number): number {
    return (String(step).split('.')[1] ?? '').length;
  }

  private get rtl(): boolean {
    return getComputedStyle(this.element).direction === 'rtl';
  }

  private get reducedMotion(): boolean {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }
}
