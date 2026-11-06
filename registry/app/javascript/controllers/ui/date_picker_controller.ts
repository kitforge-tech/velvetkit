import { Controller } from '@hotwired/stimulus';
import { toIso, toTyped } from './_internal/date_format.js';

// Connects to data-controller="ui--date-picker"
//
// A typed field with a calendar beside it, over a hidden ISO input the form
// actually submits.
//
// Typed first, calendar second, because people who know a date type it in a
// second, and reaching a date years away by clicking back through a calendar
// takes month after month. The calendar is for dates you pick rather than know.
//
// The written order is not decided here. Ruby derives it from
// date.formats.typed in the locale and passes it in as "DMY" plus a
// separator, so one locale file governs what the field accepts, what it shows
// and what the hint says. The parsing itself is in _internal/date_format.

export default class extends Controller<HTMLElement> {
  static targets = ['input', 'hidden', 'calendar', 'panel', 'toggle'];
  static values = {
    moduleUrl: String,
    order: { type: String, default: 'DMY' },
    separator: { type: String, default: '/' },
  };

  declare readonly inputTarget: HTMLInputElement;
  declare readonly hiddenTarget: HTMLInputElement;
  declare readonly calendarTarget: HTMLElement;
  declare readonly panelTarget: HTMLElement;
  declare readonly toggleTarget: HTMLButtonElement;
  declare readonly moduleUrlValue: string;
  declare readonly orderValue: string;
  declare readonly separatorValue: string;

  private loaded = false;

  connect() {
    // The typed field is the source of truth on load, so a value already on
    // the record shows in the locale's written format.
    this.inputTarget.value = this.toTyped(this.hiddenTarget.value);
  }

  // Parsed on every keystroke rather than on blur, so a half-typed date simply
  // clears the hidden field instead of submitting yesterday's value.
  typed() {
    const iso = this.toIso(this.inputTarget.value);
    this.hiddenTarget.value = iso ?? '';
    this.inputTarget.setAttribute('aria-invalid', this.invalid() ? 'true' : 'false');
    if (iso && this.loaded) this.calendarTarget.setAttribute('value', iso);
  }

  async toggle(event: Event) {
    event.preventDefault();
    if (!this.panelTarget.hidden) return this.close();

    await this.load();
    this.panelTarget.hidden = false;
    this.toggleTarget.setAttribute('aria-expanded', 'true');
    (this.calendarTarget as HTMLElement & { focus?: () => void }).focus?.();
  }

  // Cally fires `change` with the chosen date on its own value attribute.
  picked() {
    const iso = (this.calendarTarget as HTMLElement & { value?: string }).value;
    if (!iso) return;

    this.hiddenTarget.value = iso;
    this.inputTarget.value = this.toTyped(iso);
    this.inputTarget.setAttribute('aria-invalid', 'false');
    this.close();
    this.inputTarget.focus();
  }

  close() {
    this.panelTarget.hidden = true;
    this.toggleTarget.setAttribute('aria-expanded', 'false');
  }

  // Clicking away and Escape both close it, which is what every other menu in
  // the app does.
  closeOnOutsideClick(event: Event) {
    if (this.panelTarget.hidden) return;
    if (this.element.contains(event.target as Node)) return;

    this.close();
  }

  closeOnEscape(event: KeyboardEvent) {
    if (event.key === 'Escape' && !this.panelTarget.hidden) {
      this.close();
      this.toggleTarget.focus();
    }
  }

  private async load() {
    if (this.loaded) return;

    await import(this.moduleUrlValue);
    this.loaded = true;
    if (this.hiddenTarget.value) this.calendarTarget.setAttribute('value', this.hiddenTarget.value);
  }

  private invalid() {
    const typed = this.inputTarget.value.trim();
    return typed !== '' && this.toIso(typed) === null;
  }

  private toIso(typed: string): string | null {
    return toIso(typed, this.orderValue);
  }

  private toTyped(iso: string): string {
    return toTyped(iso, this.orderValue, this.separatorValue);
  }
}
