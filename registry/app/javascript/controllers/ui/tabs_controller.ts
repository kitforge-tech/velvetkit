import { Controller } from '@hotwired/stimulus';

export default class extends Controller<HTMLElement> {
  static targets = ['trigger', 'panel'];
  static values = { active: String };

  declare readonly triggerTargets: HTMLButtonElement[];
  declare readonly panelTargets: HTMLElement[];
  declare activeValue: string;

  connect() {
    // If no active value is set, activate the first non-disabled trigger
    const value = this.activeValue || this.firstEnabledTriggerValue();
    this.sync(value);
  }

  private firstEnabledTriggerValue(): string {
    const enabled = this.triggerTargets.filter((t) => !t.disabled);
    return enabled[0]?.dataset.value || '';
  }

  activate(event: Event) {
    const btn = event.currentTarget as HTMLButtonElement;
    if (btn.disabled) return;
    const value = btn.dataset.value!;
    this.activeValue = value;
    this.sync(value);
    btn.focus();
  }

  keydown(event: KeyboardEvent) {
    const enabled = this.triggerTargets.filter((t) => !t.disabled);
    if (enabled.length === 0) return;
    const currentIndex = enabled.indexOf(event.currentTarget as HTMLButtonElement);
    let next = -1;
    switch (event.key) {
      case 'ArrowRight':
        next = (currentIndex + 1) % enabled.length;
        break;
      case 'ArrowLeft':
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
    this.activeValue = target.dataset.value!;
    this.sync(this.activeValue);
    target.focus();
  }

  private sync(value: string) {
    this.triggerTargets.forEach((t) => {
      const active = t.dataset.value === value;
      t.dataset.state = active ? 'active' : 'inactive';
      t.setAttribute('aria-selected', active ? 'true' : 'false');
      t.tabIndex = active ? 0 : -1;
    });
    this.panelTargets.forEach((p) => {
      const active = p.dataset.value === value;
      p.dataset.state = active ? 'active' : 'inactive';
      if (active) p.removeAttribute('hidden');
      else p.setAttribute('hidden', '');
    });
  }
}
