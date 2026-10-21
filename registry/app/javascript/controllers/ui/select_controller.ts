import { Controller } from '@hotwired/stimulus';
import { useFloating } from './_internal/use_floating.js';
import { useDismiss } from './_internal/use_dismiss.js';

// Connects to data-controller="ui--select"
//
// The WAI-ARIA select-only combobox, with an optional search box. Focus stays
// on the trigger, or moves to the search box when there is one; either way
// the highlighted option is announced through aria-activedescendant.
//
// The hidden native <select> holds the value. Every pick is written to it and
// announced with `input` and `change`, so forms and listeners see an ordinary
// select. A multiple select stays open while you tick options.
export default class extends Controller<HTMLElement> {
  static targets = ['trigger', 'value', 'panel', 'listbox', 'option', 'native', 'search', 'empty'];
  static values = { multiple: Boolean, summary: String, placeholder: String };

  declare readonly triggerTarget: HTMLButtonElement;
  declare readonly valueTarget: HTMLElement;
  declare readonly panelTarget: HTMLElement;
  declare readonly optionTargets: HTMLElement[];
  declare readonly nativeTarget: HTMLSelectElement;
  declare readonly hasSearchTarget: boolean;
  declare readonly searchTarget: HTMLInputElement;
  declare readonly hasEmptyTarget: boolean;
  declare readonly emptyTarget: HTMLElement;
  declare readonly multipleValue: boolean;
  declare readonly summaryValue: string;
  declare readonly placeholderValue: string;

  private isOpen = false;
  private active: HTMLElement | null = null;
  private typed = '';
  private typedAt = 0;
  private floatingCleanup: (() => void) | null = null;
  private dismissCleanup: (() => void) | null = null;
  private onReset = () => requestAnimationFrame(() => this.sync());
  private onInvalid = () => this.triggerTarget.setAttribute('aria-invalid', 'true');

  connect() {
    this.nativeTarget.form?.addEventListener('reset', this.onReset);
    this.nativeTarget.addEventListener('invalid', this.onInvalid);
    this.sync();
  }

  disconnect() {
    this.nativeTarget.form?.removeEventListener('reset', this.onReset);
    this.nativeTarget.removeEventListener('invalid', this.onInvalid);
    this.teardown();
  }

  toggle(event: Event) {
    event.preventDefault();
    if (this.isOpen) this.close();
    else this.open();
  }

  // Keys on the trigger and, when there is one, the search box.
  keydown(event: KeyboardEvent) {
    const fromSearch = event.currentTarget === (this.hasSearchTarget ? this.searchTarget : null);

    if (!this.isOpen) {
      if (['ArrowDown', 'ArrowUp', 'Enter', ' '].includes(event.key)) {
        event.preventDefault();
        this.open(event.key === 'ArrowUp' ? 'last' : 'first');
      } else if (this.isPrintable(event) && !this.multipleValue) {
        this.typeahead(event.key, true);
      }
      return;
    }

    const visible = this.visible();
    const index = this.active ? visible.indexOf(this.active) : -1;
    const step = (to: number) => {
      event.preventDefault();
      this.highlight(visible[Math.max(0, Math.min(to, visible.length - 1))]);
    };

    switch (event.key) {
      case 'ArrowDown': return step(index + 1);
      case 'ArrowUp': return step(index - 1);
      case 'PageDown': return step(index + 10);
      case 'PageUp': return step(index - 10);
      case 'Home': if (!fromSearch) step(0); return;
      case 'End': if (!fromSearch) step(visible.length - 1); return;
      case 'Enter':
        event.preventDefault();
        if (this.active) this.pick(this.active);
        return;
      case ' ':
        if (fromSearch) return; // a space is part of the search
        event.preventDefault();
        if (this.active) this.pick(this.active);
        return;
      case 'Escape':
        // Only the dropdown: not the Dialog or Sheet it may sit in.
        event.preventDefault();
        event.stopPropagation();
        this.close();
        return;
      case 'Tab':
        this.close(false);
        return;
      default:
        if (!fromSearch && this.isPrintable(event)) this.typeahead(event.key, false);
    }
  }

  filter() {
    if (!this.hasSearchTarget) return;

    const query = this.searchTarget.value.trim().toLowerCase();
    this.optionTargets.forEach((option) => {
      option.hidden = query !== '' && !this.label(option).toLowerCase().includes(query);
    });
    const visible = this.visible();
    if (this.hasEmptyTarget) this.emptyTarget.hidden = visible.length > 0;
    if (!this.active || this.active.hidden) this.highlight(visible[0] ?? null);
  }

  choose(event: Event) {
    this.pick(event.currentTarget as HTMLElement);
  }

  hover(event: Event) {
    const option = event.currentTarget as HTMLElement;
    if (option !== this.active) this.highlight(option, false);
  }

  // Clicking inside the list must not take focus away.
  keepFocus(event: Event) {
    event.preventDefault();
  }

  private open(start: 'first' | 'last' = 'first') {
    if (this.isOpen || this.triggerTarget.disabled) return;

    this.panelTarget.style.minWidth = `${this.triggerTarget.offsetWidth}px`;
    this.floatingCleanup = useFloating(this.triggerTarget, this.panelTarget, {
      placement: 'bottom-start',
      offset: 4,
      strategy: 'fixed',
    }).destroy;
    this.dismissCleanup = useDismiss(this.panelTarget, {
      escapeKey: false, // handled in keydown, so it can stop at the dropdown
      outsideClickExclude: this.triggerTarget,
      onDismiss: () => this.close(false),
    }).destroy;

    this.panelTarget.hidden = false;
    this.panelTarget.dataset.state = 'open';
    this.triggerTarget.setAttribute('aria-expanded', 'true');
    this.isOpen = true;

    if (this.hasSearchTarget) {
      this.searchTarget.value = '';
      this.filter();
      this.searchTarget.focus();
    }

    const chosen = this.optionTargets.find((o) => o.getAttribute('aria-selected') === 'true' && o.dataset.value !== '');
    const visible = this.visible();
    this.highlight(chosen ?? (start === 'last' ? visible[visible.length - 1] : visible[0]) ?? null);
  }

  private close(refocus = true) {
    if (!this.isOpen) return;

    this.teardown();
    this.panelTarget.hidden = true;
    this.panelTarget.dataset.state = 'closed';
    this.triggerTarget.setAttribute('aria-expanded', 'false');
    this.focusTarget().removeAttribute('aria-activedescendant');
    this.highlight(null);
    this.isOpen = false;
    if (refocus) this.triggerTarget.focus();
  }

  private pick(option: HTMLElement) {
    const value = option.dataset.value ?? '';
    const native = this.nativeTarget;
    const before = Array.from(native.selectedOptions).map((o) => o.value).join('\n');

    if (this.multipleValue) {
      const item = Array.from(native.options).find((o) => o.value === value);
      if (item) item.selected = !item.selected;
    } else {
      native.value = value;
    }

    this.sync();
    if (!this.multipleValue) this.close();

    if (Array.from(native.selectedOptions).map((o) => o.value).join('\n') !== before) {
      native.dispatchEvent(new Event('input', { bubbles: true }));
      native.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  // Ticks and trigger text, from the native select's current state.
  private sync() {
    const chosen = new Set(Array.from(this.nativeTarget.selectedOptions).map((o) => o.value));
    this.optionTargets.forEach((option) => {
      const on = chosen.has(option.dataset.value ?? '');
      option.setAttribute('aria-selected', String(on));
      const check = option.querySelector<HTMLElement>('[data-ui--select-target="check"]');
      if (check) check.hidden = !on;
    });

    const labels = this.optionTargets
      .filter((o) => o.dataset.value !== '' && chosen.has(o.dataset.value ?? ''))
      .map((o) => this.label(o));
    const text = labels.length > 2 ? this.summaryValue.replace('%{count}', String(labels.length)) : labels.join(', ');
    this.valueTarget.textContent = text || this.placeholderValue;
    this.valueTarget.classList.toggle('text-muted-foreground', !text);
    if (this.nativeTarget.checkValidity()) this.triggerTarget.removeAttribute('aria-invalid');
  }

  private highlight(option: HTMLElement | null, scroll = true) {
    this.optionTargets.forEach((o) => {
      if (o === option) o.dataset.highlighted = '';
      else delete o.dataset.highlighted;
    });
    this.active = option;
    if (!option) return;

    this.focusTarget().setAttribute('aria-activedescendant', option.id);
    if (scroll) option.scrollIntoView({ block: 'nearest' });
  }

  // Jump to the next option starting with what was typed in the last half
  // second. Closed, it changes the value directly, as a native select does.
  private typeahead(key: string, closed: boolean) {
    const now = Date.now();
    this.typed = now - this.typedAt > 500 ? key : this.typed + key;
    this.typedAt = now;

    const query = this.typed.toLowerCase();
    const options = this.visible();
    const current = closed
      ? options.findIndex((o) => o.getAttribute('aria-selected') === 'true')
      : options.indexOf(this.active as HTMLElement);
    const ordered = [...options.slice(current + 1), ...options.slice(0, current + 1)];
    const match = ordered.find((o) => this.label(o).toLowerCase().startsWith(query));
    if (!match) return;

    if (closed) this.pick(match);
    else this.highlight(match);
  }

  private visible() {
    return this.optionTargets.filter((o) => !o.hidden);
  }

  private label(option: HTMLElement) {
    return option.textContent?.trim() ?? '';
  }

  // Where keyboard focus sits while the list is open.
  private focusTarget(): HTMLElement {
    return this.hasSearchTarget ? this.searchTarget : this.triggerTarget;
  }

  private isPrintable(event: KeyboardEvent) {
    return event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey;
  }

  private teardown() {
    this.floatingCleanup?.();
    this.dismissCleanup?.();
    this.floatingCleanup = null;
    this.dismissCleanup = null;
  }
}
