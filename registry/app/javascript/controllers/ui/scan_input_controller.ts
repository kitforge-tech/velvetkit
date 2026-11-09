import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--scan-input"
//
// A scanner types a code and presses Enter (or Tab). On that key this fires
// `ui--scan-input:scan`, then submits the form with the code and empties the
// field. While a Turbo submission is on its way, later codes queue and go
// one after another, so none is lost to a busy form. Focus is kept on the
// field when it would otherwise fall to the page.
const SCANNED_FOR = 700;

export default class extends Controller<HTMLElement> {
  static targets = ['field'];
  static values = {
    submit: { type: Boolean, default: true },
    clear: { type: Boolean, default: true },
    keepFocus: { type: Boolean, default: true },
    capture: Boolean,
    suffix: { type: String, default: 'enter' },
  };

  declare readonly fieldTarget: HTMLInputElement;
  declare readonly submitValue: boolean;
  declare readonly clearValue: boolean;
  declare readonly keepFocusValue: boolean;
  declare readonly captureValue: boolean;
  declare readonly suffixValue: string;

  private queue: string[] = [];
  private sending = false;
  private form: HTMLFormElement | null = null;
  private scannedTimer?: number;

  connect() {
    this.form = this.fieldTarget.form;
    this.form?.addEventListener('turbo:submit-start', this.started);
    this.form?.addEventListener('turbo:submit-end', this.ended);
    this.fieldTarget.addEventListener('blur', this.blurred);
    if (this.keepFocusValue) document.addEventListener('visibilitychange', this.refocus);
    if (this.captureValue) document.addEventListener('keydown', this.captured);
    // autofocus only works on page load; back in a Turbo update, focus here.
    if (this.fieldTarget.autofocus) this.refocus();
  }

  disconnect() {
    this.form?.removeEventListener('turbo:submit-start', this.started);
    this.form?.removeEventListener('turbo:submit-end', this.ended);
    this.fieldTarget.removeEventListener('blur', this.blurred);
    document.removeEventListener('visibilitychange', this.refocus);
    document.removeEventListener('keydown', this.captured);
    window.clearTimeout(this.scannedTimer);
  }

  key(event: KeyboardEvent) {
    if (event.isComposing || !this.isSuffix(event)) return;

    event.preventDefault();
    const code = this.fieldTarget.value.trim();
    if (!code) return;

    this.flash();
    const scan = new CustomEvent('ui--scan-input:scan', { detail: { code }, bubbles: true, cancelable: true });
    this.element.dispatchEvent(scan);
    if (scan.defaultPrevented || !this.submitValue || !this.form) {
      if (this.clearValue) this.fieldTarget.value = '';
      return;
    }

    if (this.sending) {
      this.queue.push(code);
      if (this.clearValue) this.fieldTarget.value = '';
    } else {
      this.send(code);
    }
  }

  // The form data is read as the submit event runs, so the field can be
  // emptied straight after.
  private send(code: string) {
    this.fieldTarget.value = code;
    this.form?.requestSubmit();
    if (this.clearValue) this.fieldTarget.value = '';
  }

  private started = () => {
    this.sending = true;
  };

  private ended = () => {
    this.sending = false;
    const next = this.queue.shift();
    if (next !== undefined) this.send(next);
  };

  private isSuffix(event: KeyboardEvent): boolean {
    if (event.altKey || event.ctrlKey || event.metaKey) return false;
    if (this.suffixValue === 'tab') return event.key === 'Tab' && !event.shiftKey;

    return event.key === 'Enter';
  }

  private flash() {
    this.element.dataset.scanned = '';
    window.clearTimeout(this.scannedTimer);
    this.scannedTimer = window.setTimeout(() => delete this.element.dataset.scanned, SCANNED_FOR);
  }

  // Only when focus has fallen to the page: a person moving to another field,
  // a button or a dialog keeps it.
  private blurred = () => {
    if (!this.keepFocusValue) return;

    requestAnimationFrame(() => this.refocus());
  };

  private refocus = () => {
    const field = this.fieldTarget;
    if (document.visibilityState !== 'visible' || field.disabled || field.readOnly) return;
    if (!this.keepFocusValue && !field.autofocus) return;

    const active = document.activeElement;
    if (active && active !== document.body && active !== document.documentElement) return;

    field.focus({ preventScroll: true });
  };

  // Typed anywhere but another field, a character goes to this one: focusing it
  // during keydown lets the browser put the key there.
  private captured = (event: KeyboardEvent) => {
    if (event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.key.length !== 1) return;
    if (this.fieldTarget.disabled || this.isEditable(event.target)) return;
    // Space presses a focused button; leave that alone.
    if (event.key === ' ' && event.target instanceof HTMLElement && event.target.closest('button, a, [role=button]')) return;

    this.fieldTarget.focus({ preventScroll: true });
  };

  private isEditable(target: EventTarget | null): boolean {
    if (!(target instanceof HTMLElement)) return false;

    return target.isContentEditable || target.closest('input, textarea, select, [role=textbox], [role=combobox]') !== null;
  }
}
