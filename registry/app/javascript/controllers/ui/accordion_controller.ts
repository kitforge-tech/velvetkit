import { Controller } from '@hotwired/stimulus';

export default class extends Controller<HTMLElement> {
  static targets = ['item', 'trigger', 'content'];
  static values = {
    type: { type: String, default: 'single' },
    values: { type: Array, default: [] },
  };

  declare readonly itemTargets: HTMLElement[];
  declare readonly triggerTargets: HTMLButtonElement[];
  declare readonly contentTargets: HTMLElement[];
  declare typeValue: string;
  declare valuesValue: string[];

  connect() {
    this.sync();
  }

  toggle(event: Event) {
    const trigger = event.currentTarget as HTMLButtonElement;
    const item = trigger.closest("[data-ui--accordion-target='item']") as HTMLElement;
    if (!item) return;
    const value = item.dataset.value!;
    const open = !this.valuesValue.includes(value);

    if (this.typeValue === 'single') {
      if (open) {
        this.valuesValue = [value];
      } else {
        this.valuesValue = [];
      }
    } else {
      if (open) {
        this.valuesValue = [...this.valuesValue, value];
      } else {
        this.valuesValue = this.valuesValue.filter((v) => v !== value);
      }
    }

    this.sync();
  }

  keydown(event: KeyboardEvent) {
    const enabled = this.triggerTargets.filter((t) => !t.disabled);
    if (enabled.length === 0) return;
    const currentIndex = enabled.indexOf(event.currentTarget as HTMLButtonElement);
    let next = -1;

    switch (event.key) {
      case 'ArrowDown':
        next = (currentIndex + 1) % enabled.length;
        break;
      case 'ArrowUp':
        next = (currentIndex - 1 + enabled.length) % enabled.length;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = enabled.length - 1;
        break;
      default:
        return;
    }

    event.preventDefault();
    const target = enabled[next];
    if (!target) return;
    target.focus();
  }

  private sync() {
    this.itemTargets.forEach((item) => {
      const value = item.dataset.value!;
      const open = this.valuesValue.includes(value);
      item.dataset.state = open ? 'open' : 'closed';
    });
    this.triggerTargets.forEach((trigger) => {
      const item = trigger.closest("[data-ui--accordion-target='item']") as HTMLElement;
      if (!item) return;
      const value = item.dataset.value!;
      const open = this.valuesValue.includes(value);
      trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
      trigger.dataset.state = open ? 'open' : 'closed';
    });
    this.contentTargets.forEach((content) => {
      const item = content.closest("[data-ui--accordion-target='item']") as HTMLElement;
      if (!item) return;
      const value = item.dataset.value!;
      const open = this.valuesValue.includes(value);
      content.dataset.state = open ? 'open' : 'closed';
      if (open) {
        content.removeAttribute('inert');
      } else {
        content.setAttribute('inert', '');
      }
    });
  }
}
