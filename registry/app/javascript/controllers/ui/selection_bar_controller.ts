import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--selection-bar"
//
// Watches the checkboxes in the element named by `for`: counts the checked
// ones, shows the bar while there are any, keeps "select all" in step, and
// checks a run of boxes on Shift-click. The boxes are found afresh each time,
// so rows added or replaced by Turbo count too.
const ITEM = 'input[type="checkbox"][data-selection="item"]:not(:disabled)';
const ALL = 'input[type="checkbox"][data-selection="all"]';

export default class extends Controller<HTMLElement> {
  static targets = ['count'];
  static values = { for: String, one: String, other: String };

  declare readonly countTarget: HTMLElement;
  declare readonly forValue: string;
  declare readonly oneValue: string;
  declare readonly otherValue: string;

  // Not `scope`: Stimulus has its own.
  private list: HTMLElement | null = null;
  private observer?: MutationObserver;
  private last: HTMLInputElement | null = null;
  private lastCount = -1;

  connect() {
    this.list = document.getElementById(this.forValue);
    if (!this.list) return;

    this.list.addEventListener('click', this.clicked);
    this.list.addEventListener('change', this.changed);
    document.addEventListener('keydown', this.keydown);
    this.observer = new MutationObserver(() => this.update());
    this.observer.observe(this.list, { childList: true, subtree: true });
    this.update();
  }

  disconnect() {
    this.list?.removeEventListener('click', this.clicked);
    this.list?.removeEventListener('change', this.changed);
    document.removeEventListener('keydown', this.keydown);
    this.observer?.disconnect();
  }

  clear() {
    const focused = this.element.contains(document.activeElement);
    this.items.forEach((box) => (box.checked = false));
    this.update();
    // The clear button hides with the bar, so focus goes back to the list.
    if (focused) (this.last ?? this.items[0])?.focus();
  }

  // Shift-click checks or unchecks everything between the last box clicked and
  // this one, as this one now is.
  private clicked = (event: MouseEvent) => {
    const box = event.target as HTMLElement;
    if (!(box instanceof HTMLInputElement) || !box.matches(ITEM)) return;

    const items = this.items;
    if (event.shiftKey && this.last && this.last !== box) {
      const [from, to] = [items.indexOf(this.last), items.indexOf(box)].sort((a, b) => a - b);
      if (from >= 0) items.slice(from, to + 1).forEach((item) => (item.checked = box.checked));
    }
    this.last = box;
  };

  private changed = (event: Event) => {
    const box = event.target as HTMLElement;
    if (box instanceof HTMLInputElement && box.matches(ALL)) {
      this.items.forEach((item) => (item.checked = box.checked));
    }
    this.update();
  };

  private keydown = (event: KeyboardEvent) => {
    if (event.key !== 'Escape' || this.checked.length === 0 || event.defaultPrevented) return;
    const target = event.target as Node;
    if (!this.element.contains(target) && !this.list?.contains(target)) return;

    event.preventDefault();
    this.clear();
  };

  private update() {
    const items = this.items;
    const checked = this.checked;
    const count = checked.length;
    this.list?.querySelectorAll<HTMLInputElement>(ALL).forEach((all) => {
      all.checked = count > 0 && count === items.length;
      all.indeterminate = count > 0 && count < items.length;
    });
    this.list?.toggleAttribute('data-selecting', count > 0);
    this.element.hidden = count === 0;
    const text = (count === 1 ? this.oneValue : this.otherValue).replace('%{count}', String(count));
    // Only when it changes: a bar inside the list it watches would otherwise
    // set off its own observer.
    if (this.countTarget.textContent !== text) this.countTarget.textContent = text;

    if (count === this.lastCount) return;
    this.lastCount = count;
    this.dispatch('change', { prefix: 'selection-bar', detail: { count, values: checked.map((box) => box.value) } });
  }

  private get items(): HTMLInputElement[] {
    return Array.from(this.list?.querySelectorAll<HTMLInputElement>(ITEM) ?? []);
  }

  private get checked(): HTMLInputElement[] {
    return this.items.filter((box) => box.checked);
  }
}
