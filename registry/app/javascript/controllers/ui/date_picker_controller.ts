import { Controller } from '@hotwired/stimulus';
import { maskDate, toIso, toTyped } from './_internal/date_format.js';

// Connects to data-controller="ui--date-picker"
//
// One typed field, or two for a range, over hidden ISO inputs the form
// actually submits, and a calendar under them.
//
// The fields take digits and put the separators in as you type, in the
// locale's order, which Ruby derives from date.formats.typed and passes in as
// "DMY" plus a separator. Clicking or tabbing into a field opens the calendar;
// a date or range picked there, or a preset, fills the fields and fires
// `change`.
//
// The calendar is Vanilla Calendar Pro, and its stylesheet, both loaded the
// first time it opens.
type CalendarInstance = {
  init: () => void;
  destroy: () => void;
  set: (options: Record<string, unknown>) => void;
  context: { selectedDates: string[] };
};
type CalendarClass = new (element: HTMLElement, options: Record<string, unknown>) => CalendarInstance;
type Labels = { pickEnd: string; previous: string; next: string; days: string };

const WIDE = '(min-width: 640px)';
let calendarModule: Promise<{ Calendar: CalendarClass; months: unknown }> | null = null;
const stylesheets = new Map<string, Promise<void>>();

export default class extends Controller<HTMLElement> {
  static targets = ['field', 'hidden', 'panel', 'calendar', 'toggle', 'clear', 'preset', 'status'];
  static values = {
    moduleUrl: String,
    styleUrl: String,
    order: { type: String, default: 'DMY' },
    separator: { type: String, default: '/' },
    range: Boolean,
    min: String,
    max: String,
    locale: { type: String, default: 'en-IN' },
    labels: Object,
  };

  declare readonly fieldTargets: HTMLInputElement[];
  declare readonly hiddenTargets: HTMLInputElement[];
  declare readonly panelTarget: HTMLElement;
  declare readonly calendarTarget: HTMLElement;
  declare readonly toggleTarget: HTMLButtonElement;
  declare readonly clearTarget: HTMLButtonElement;
  declare readonly presetTargets: HTMLButtonElement[];
  declare readonly hasStatusTarget: boolean;
  declare readonly statusTarget: HTMLElement;
  declare readonly moduleUrlValue: string;
  declare readonly styleUrlValue: string;
  declare readonly orderValue: string;
  declare readonly separatorValue: string;
  declare readonly rangeValue: boolean;
  declare readonly minValue: string;
  declare readonly maxValue: string;
  declare readonly localeValue: string;
  declare readonly labelsValue: Labels;

  private calendar: CalendarInstance | null = null;
  private calendarMonths = 0;
  private quiet = false;

  connect() {
    this.fieldTargets.forEach((field, i) => (field.value = this.typedOf(this.hiddenTargets[i].value)));
  }

  disconnect() {
    this.calendar?.destroy();
    this.calendar = null;
  }

  // ── Typing ───────────────────────────────────────────────────────────────

  // Masked as it's typed, then parsed: a half-typed date clears its hidden
  // field rather than submitting the last one. A To before the From is marked
  // and not submitted.
  typed(event: Event) {
    const field = event.target as HTMLInputElement;
    const growing = (event as InputEvent).inputType?.startsWith('insert') ?? true;
    const masked = maskDate(field.value, this.orderValue, this.separatorValue, growing);
    if (masked !== field.value) field.value = masked;

    const dates = this.fieldTargets.map((f) => toIso(f.value, this.orderValue));
    const backwards = this.rangeValue && !!(dates[0] && dates[1] && dates[1] < dates[0]);
    this.fieldTargets.forEach((f, i) => {
      const bad = (f.value.trim() !== '' && dates[i] === null) || (backwards && i === 1);
      this.hiddenTargets[i].value = bad ? '' : (dates[i] ?? '');
      f.setAttribute('aria-invalid', String(bad));
    });
    this.afterChange(false);

    const chosen = this.hiddenTargets.map((h) => h.value).filter(Boolean);
    if (this.calendar && chosen.length === this.fieldTargets.length) this.showOnCalendar(chosen);
  }

  // ArrowDown from a field moves into the calendar.
  keydown(event: KeyboardEvent) {
    if (event.key !== 'ArrowDown') return;

    event.preventDefault();
    this.open().then(() => {
      const day = this.calendarTarget.querySelector<HTMLElement>('[data-vc-date-selected] button, [data-vc-date-today] button, [data-vc-date] button');
      day?.focus();
    });
  }

  // ── Opening and closing ─────────────────────────────────────────────────

  async open() {
    if (this.quiet || !this.panelTarget.hidden || this.fieldTargets[0].disabled) return;

    await this.build();
    this.panelTarget.hidden = false;
    this.toggleTarget.setAttribute('aria-expanded', 'true');
    this.keepOnScreen();
  }

  async toggle(event: Event) {
    event.preventDefault();
    if (this.panelTarget.hidden) {
      await this.open();
      this.fieldTargets[0].focus();
    } else {
      this.close();
    }
  }

  close() {
    if (this.panelTarget.hidden) return;

    this.panelTarget.hidden = true;
    this.toggleTarget.setAttribute('aria-expanded', 'false');
    if (this.hasStatusTarget) this.statusTarget.textContent = '';
  }

  // By the path the click took when it happened: the calendar redraws its
  // heading as it's clicked, so by now the clicked button may have left the page.
  closeOnOutsideClick(event: Event) {
    if (!event.composedPath().includes(this.element)) this.close();
  }

  closeOnEscape(event: KeyboardEvent) {
    if (event.key !== 'Escape' || this.panelTarget.hidden) return;

    this.close();
    this.focusField();
  }

  // Tabbing out of the whole picker closes it.
  leave(event: FocusEvent) {
    const next = event.relatedTarget as Node | null;
    if (next && !this.element.contains(next)) this.close();
  }

  // ── Choosing ─────────────────────────────────────────────────────────────

  preset(event: Event & { params: { from: string; to: string } }) {
    this.choose([event.params.from, event.params.to]);
  }

  clear() {
    this.fieldTargets.forEach((f) => {
      f.value = '';
      f.setAttribute('aria-invalid', 'false');
    });
    this.hiddenTargets.forEach((h) => (h.value = ''));
    this.calendar?.set({ selectedDates: [] });
    this.afterChange(true);
    this.focusField();
  }

  private choose(dates: string[]) {
    this.hiddenTargets.forEach((h, i) => (h.value = dates[i] ?? ''));
    this.fieldTargets.forEach((f, i) => {
      f.value = this.typedOf(dates[i] ?? '');
      f.setAttribute('aria-invalid', 'false');
    });
    if (this.calendar) this.showOnCalendar(dates);
    this.afterChange(true);
    this.close();
    this.focusField();
  }

  // The clear button and the pressed preset follow the value; a choice also
  // tells the form.
  private afterChange(announce: boolean) {
    const values = this.hiddenTargets.map((h) => h.value);
    const filled = values.some(Boolean);
    if (!this.fieldTargets[0].required) this.clearTarget.hidden = !filled;
    this.presetTargets.forEach((button) => {
      const on = button.getAttribute('data-ui--date-picker-from-param') === values[0] &&
        button.getAttribute('data-ui--date-picker-to-param') === values[1];
      button.setAttribute('aria-pressed', String(on));
    });
    if (announce) this.hiddenTargets[this.hiddenTargets.length - 1].dispatchEvent(new Event('change', { bubbles: true }));
  }

  private focusField() {
    this.quiet = true;
    this.fieldTargets[0].focus();
    this.quiet = false;
  }

  // ── The calendar ─────────────────────────────────────────────────────────

  private async build() {
    const months = this.rangeValue && window.matchMedia(WIDE).matches ? 2 : 1;
    if (this.calendar && this.calendarMonths === months) return;

    const [{ Calendar, months: monthsExtension }] = await Promise.all([this.loadModule(), this.loadStyles()]);
    this.calendar?.destroy();
    this.calendarTarget.replaceChildren();
    const selected = this.hiddenTargets.map((h) => h.value).filter(Boolean);
    const first = selected[0] ? new Date(`${selected[0]}T00:00:00`) : null;

    this.calendar = new Calendar(this.calendarTarget, {
      // Two months side by side need the library's months extension.
      ...(months > 1 ? { extensions: [monthsExtension] } : {}),
      type: months > 1 ? 'multiple' : 'default',
      displayMonthsCount: months,
      monthsToSwitch: 1,
      selectionDatesMode: this.rangeValue ? 'multiple-ranged' : 'single',
      enableEdgeDatesOnly: true,
      enableDateToggle: false,
      enableJumpToSelectedDate: true,
      displayDatesOutside: months === 1,
      selectedDates: this.rangeValue && selected.length < 2 ? [] : selected,
      ...(first ? { selectedMonth: first.getMonth(), selectedYear: first.getFullYear() } : {}),
      ...(this.minValue ? { dateMin: this.minValue } : {}),
      ...(this.maxValue ? { dateMax: this.maxValue } : {}),
      firstWeekday: 1,
      locale: this.localeValue,
      // Weekends aren't marked: in a shop, Saturday is a working day.
      selectedWeekends: [],
      selectedTheme: 'light',
      themeAttrDetect: false,
      labels: { arrowPrev: { month: this.labelsValue.previous }, arrowNext: { month: this.labelsValue.next } },
      onClickDate: (self: CalendarInstance) => this.picked(self),
    });
    this.calendar.init();
    this.calendarMonths = months;
  }

  private picked(self: CalendarInstance) {
    const dates = [...self.context.selectedDates].sort();
    if (!this.rangeValue) {
      if (dates[0]) this.choose([dates[0]]);
      return;
    }

    if (dates.length >= 2) {
      this.choose([dates[0], dates[dates.length - 1]]);
    } else if (this.hasStatusTarget) {
      this.statusTarget.textContent = this.labelsValue.pickEnd;
    }
  }

  private showOnCalendar(dates: string[]) {
    const first = new Date(`${dates[0]}T00:00:00`);
    this.calendar?.set({ selectedDates: dates, selectedMonth: first.getMonth(), selectedYear: first.getFullYear() });
  }

  // Kept inside the window: the panel lines up with the field's right edge
  // when there isn't room to its right. A phone gets it as a sheet instead.
  private keepOnScreen() {
    const panel = this.panelTarget;
    panel.style.left = '';
    panel.style.right = '';
    if (!window.matchMedia(WIDE).matches) return;

    if (panel.getBoundingClientRect().right > document.documentElement.clientWidth - 8) {
      panel.style.left = 'auto';
      panel.style.right = '0';
    }
  }

  private loadModule() {
    calendarModule ??= import(this.moduleUrlValue);
    return calendarModule;
  }

  // The stylesheet once per page, waited for, so the calendar never shows unstyled.
  private loadStyles(): Promise<void> {
    const url = this.styleUrlValue;
    if (!url) return Promise.resolve();
    if (!stylesheets.has(url)) {
      stylesheets.set(url, new Promise((resolve) => {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = url;
        link.onload = () => resolve();
        link.onerror = () => resolve();
        document.head.append(link);
      }));
    }
    return stylesheets.get(url)!;
  }

  private typedOf(iso: string) {
    return toTyped(iso, this.orderValue, this.separatorValue);
  }
}
