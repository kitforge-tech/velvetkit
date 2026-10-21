import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--date-picker"
//
// A typed field with a calendar beside it, over a hidden ISO input the form
// actually submits.
//
// Typed first, calendar second, because the field this exists for is date of
// birth: a clerk with a stack of admission forms types 02/05/2012 in a second,
// and reaching 2012 by clicking back through a calendar takes a hundred and
// seventy months. The calendar is for dates you pick rather than know.
//
// The written order is not decided here. Ruby derives it from
// date.formats.typed in the locale and passes it in as "DMY" plus a
// separator, so one locale file governs what the field accepts, what it shows
// and what the hint says.
const ISO = /^(\d{4})-(\d{2})-(\d{2})$/;
// Any of / - . or a space between the parts: a clerk types what is on the
// form, and being strict about the separator only creates work.
const PARTS = /^(\d{1,4})[/\-. ](\d{1,4})[/\-. ](\d{1,4})$/;

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
    // the record shows in the format the school writes.
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

  // The locale's order in, ISO out. Rejects 31/02 rather than rolling it into
  // the 3rd of March, which is what Date does and how a wrong birth date gets
  // stored without anyone seeing an error.
  private toIso(typed: string): string | null {
    const match = PARTS.exec(typed.trim());
    if (!match) return null;

    const order = this.orderValue.split('');
    const day = match[order.indexOf('D') + 1];
    const month = match[order.indexOf('M') + 1];
    const year = match[order.indexOf('Y') + 1];
    if (!day || !month || !year || year.length !== 4) return null;

    const iso = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
    const date = new Date(`${iso}T00:00:00`);
    if (Number.isNaN(date.getTime())) return null;

    // Round-tripped, because Date accepts the 31st of February and quietly
    // returns the 3rd of March.
    return date.getDate() === Number(day) && date.getMonth() + 1 === Number(month) ? iso : null;
  }

  private toTyped(iso: string): string {
    const match = ISO.exec((iso ?? '').trim());
    if (!match) return '';

    const [, year, month, day] = match;
    const parts: Record<string, string> = { D: day, M: month, Y: year };
    return this.orderValue.split('').map((key) => parts[key]).join(this.separatorValue);
  }
}
