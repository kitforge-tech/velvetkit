import { Controller } from '@hotwired/stimulus';
import { toIso, toTyped } from './_internal/date_format.js';

// Connects to data-controller="ui--date-range-picker"
//
// Two typed dates over two hidden ISO fields, a range calendar and presets.
// Typing is parsed as it goes, like the date picker; a range picked on the
// calendar or from a preset fills both fields at once and fires `change`, so a
// filter form can submit itself.
//
// Cally (shared with the date picker) loads when the calendar first opens. It
// shows two months side by side where there's room and one on a phone.
type Which = 'from' | 'to';

export default class extends Controller<HTMLElement> {
  static targets = ['from', 'to', 'fromHidden', 'toHidden', 'calendar', 'panel', 'toggle', 'preset', 'firstMonth', 'secondMonth'];
  static values = {
    moduleUrl: String,
    order: { type: String, default: 'DMY' },
    separator: { type: String, default: '/' },
  };

  declare readonly fromTarget: HTMLInputElement;
  declare readonly toTarget: HTMLInputElement;
  declare readonly fromHiddenTarget: HTMLInputElement;
  declare readonly toHiddenTarget: HTMLInputElement;
  declare readonly calendarTarget: HTMLElement & { value?: string };
  declare readonly panelTarget: HTMLElement;
  declare readonly toggleTarget: HTMLButtonElement;
  declare readonly presetTargets: HTMLButtonElement[];
  declare readonly firstMonthTarget: HTMLElement;
  declare readonly hasSecondMonthTarget: boolean;
  declare readonly secondMonthTarget: HTMLElement;
  declare readonly moduleUrlValue: string;
  declare readonly orderValue: string;
  declare readonly separatorValue: string;

  private loaded = false;
  private secondMonth: HTMLElement | null = null;

  initialize() {
    if (this.hasSecondMonthTarget) this.secondMonth = this.secondMonthTarget;
  }

  connect() {
    this.fromTarget.value = this.typedOf(this.fromHiddenTarget.value);
    this.toTarget.value = this.typedOf(this.toHiddenTarget.value);
  }

  // Each field is parsed on every keystroke, so a half-typed date clears its
  // hidden field rather than submitting the last one. A To before the From is
  // marked, and not submitted.
  typed() {
    const from = toIso(this.fromTarget.value, this.orderValue);
    const to = toIso(this.toTarget.value, this.orderValue);
    const backwards = !!(from && to && to < from);
    this.fromHiddenTarget.value = from ?? '';
    this.toHiddenTarget.value = backwards ? '' : (to ?? '');
    this.markInvalid('from', this.isBad(this.fromTarget, from));
    this.markInvalid('to', this.isBad(this.toTarget, to) || backwards);
    this.syncPresets();
    if (from && to && !backwards && this.loaded) this.calendarTarget.setAttribute('value', `${from}/${to}`);
  }

  async toggle(event: Event) {
    event.preventDefault();
    if (!this.panelTarget.hidden) return this.close();

    this.fitMonths();
    await this.load();
    this.panelTarget.hidden = false;
    this.toggleTarget.setAttribute('aria-expanded', 'true');
    (this.calendarTarget as HTMLElement & { focus?: () => void }).focus?.();
  }

  // Cally sets its value to "from/to" once the second day is picked.
  picked() {
    const [from, to] = (this.calendarTarget.value ?? '').split('/');
    if (from && to) this.choose(from, to);
  }

  preset(event: Event & { params: { from: string; to: string } }) {
    this.choose(event.params.from, event.params.to);
  }

  close() {
    this.panelTarget.hidden = true;
    this.toggleTarget.setAttribute('aria-expanded', 'false');
  }

  closeOnOutsideClick(event: Event) {
    if (this.panelTarget.hidden || this.element.contains(event.target as Node)) return;

    this.close();
  }

  closeOnEscape(event: KeyboardEvent) {
    if (event.key !== 'Escape' || this.panelTarget.hidden) return;

    this.close();
    this.toggleTarget.focus();
  }

  private choose(from: string, to: string) {
    this.fromHiddenTarget.value = from;
    this.toHiddenTarget.value = to;
    this.fromTarget.value = this.typedOf(from);
    this.toTarget.value = this.typedOf(to);
    this.markInvalid('from', false);
    this.markInvalid('to', false);
    if (this.loaded) this.calendarTarget.setAttribute('value', `${from}/${to}`);
    this.syncPresets();
    this.close();
    this.toggleTarget.focus();
    this.toHiddenTarget.dispatchEvent(new Event('change', { bubbles: true }));
  }

  private syncPresets() {
    const from = this.fromHiddenTarget.value;
    const to = this.toHiddenTarget.value;
    this.presetTargets.forEach((button) => {
      const on = button.getAttribute('data-ui--date-range-picker-from-param') === from &&
        button.getAttribute('data-ui--date-range-picker-to-param') === to;
      button.setAttribute('aria-pressed', String(on));
    });
  }

  // Two months where there's room for them, one on a phone. The second month
  // is taken out rather than hidden: Cally still lays out a hidden month, and
  // on a narrow screen that locked the page up.
  private fitMonths() {
    if (!this.secondMonth) return;

    const wide = window.matchMedia('(min-width: 640px)').matches;
    this.calendarTarget.setAttribute('months', wide ? '2' : '1');
    if (wide && !this.secondMonth.isConnected) this.firstMonthTarget.after(this.secondMonth);
    if (!wide && this.secondMonth.isConnected) this.secondMonth.remove();
  }

  private async load() {
    if (this.loaded) return;

    await import(this.moduleUrlValue);
    this.loaded = true;
    const from = this.fromHiddenTarget.value;
    const to = this.toHiddenTarget.value;
    if (from && to) this.calendarTarget.setAttribute('value', `${from}/${to}`);
  }

  private isBad(input: HTMLInputElement, iso: string | null) {
    return input.value.trim() !== '' && iso === null;
  }

  private markInvalid(which: Which, invalid: boolean) {
    (which === 'from' ? this.fromTarget : this.toTarget).setAttribute('aria-invalid', String(invalid));
  }

  private typedOf(iso: string) {
    return toTyped(iso, this.orderValue, this.separatorValue);
  }
}
