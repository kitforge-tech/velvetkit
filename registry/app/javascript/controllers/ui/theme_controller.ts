import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--theme"
//
// Applies the `.dark` class to <html>, which is what `@custom-variant dark`
// in application.css keys off. The stored preference is one of three values;
// 'system' defers to the OS and keeps following it while selected. With
// nothing stored, the page is light.
//
// The same resolution logic runs in an inline <head> script (see
// layouts/_theme_script.html.erb) so the class is set before first paint. This
// controller only handles changes made after load.
type ThemePreference = 'system' | 'light' | 'dark';

const STORAGE_KEY = 'ui-theme';

export default class extends Controller<HTMLElement> {
  static targets = ['option'];

  declare readonly hasOptionTarget: boolean;
  declare readonly optionTargets: HTMLElement[];

  private media?: MediaQueryList;
  private onSystemChange?: () => void;

  connect() {
    this.media = window.matchMedia('(prefers-color-scheme: dark)');
    // An OS-level switch should move the page live, but only while the user
    // has not pinned an explicit preference.
    this.onSystemChange = () => {
      if (this.preference() === 'system') this.apply();
    };
    this.media.addEventListener('change', this.onSystemChange);
    this.apply();
  }

  disconnect() {
    if (this.media && this.onSystemChange) {
      this.media.removeEventListener('change', this.onSystemChange);
    }
  }

  // data-action="ui--theme#select" data-theme="dark"
  select(event: Event) {
    const chosen = (event.currentTarget as HTMLElement)?.dataset.theme as
      | ThemePreference
      | undefined;
    if (!chosen) return;

    localStorage.setItem(STORAGE_KEY, chosen);
    this.apply();
  }

  // Cycles light -> dark -> system, for a single-button toggle.
  cycle() {
    const order: ThemePreference[] = ['light', 'dark', 'system'];
    const next = order[(order.indexOf(this.preference()) + 1) % order.length];
    localStorage.setItem(STORAGE_KEY, next);
    this.apply();
  }

  private preference(): ThemePreference {
    const stored = this.readStored();
    return stored === 'light' || stored === 'dark' || stored === 'system'
      ? stored
      : 'light';
  }

  // Private windows and blocked site data make localStorage throw on access,
  // so every read is guarded; the page still renders in the light theme.
  private readStored(): string | null {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch {
      return null;
    }
  }

  private resolved(): 'light' | 'dark' {
    const preference = this.preference();
    if (preference !== 'system') return preference;
    return this.media?.matches ? 'dark' : 'light';
  }

  private apply() {
    const dark = this.resolved() === 'dark';
    document.documentElement.classList.toggle('dark', dark);
    document.documentElement.dataset.theme = this.preference();
    this.syncOptions();
  }

  private syncOptions() {
    if (!this.hasOptionTarget) return;

    const preference = this.preference();
    this.optionTargets.forEach((option) => {
      const selected = option.dataset.theme === preference;
      option.setAttribute('aria-checked', selected ? 'true' : 'false');
    });
  }
}
