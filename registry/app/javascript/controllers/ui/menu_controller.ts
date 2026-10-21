import { Controller } from '@hotwired/stimulus';
import { useFloating, type Placement } from './_internal/use_floating.js';
import { useDismiss } from './_internal/use_dismiss.js';

export default class extends Controller<HTMLElement> {
  static targets = ['trigger', 'content'];

  declare readonly triggerTarget: HTMLButtonElement;
  declare readonly contentTarget: HTMLElement;

  private floatingCleanup: (() => void) | null = null;
  private dismissCleanup: (() => void) | null = null;
  private isOpen = false;

  connect() {
    this.close();
  }

  disconnect() {
    this.cleanup();
  }

  toggle(event: Event) {
    event.preventDefault();
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    if (this.isOpen) return;

    const placement = this.getPlacement();
    const floating = useFloating(this.triggerTarget, this.contentTarget, {
      placement,
      offset: 4,
      flip: true,
      shift: true,
    });
    this.floatingCleanup = floating.destroy;

    const dismiss = useDismiss(this.contentTarget, {
      outsideClick: true,
      escapeKey: true,
      outsideClickExclude: this.triggerTarget,
      onDismiss: () => this.close(),
    });
    this.dismissCleanup = dismiss.destroy;

    this.contentTarget.removeAttribute('hidden');
    this.contentTarget.dataset.state = 'open';
    this.triggerTarget.setAttribute('aria-expanded', 'true');

    // Focus the checked option if this is a radio menu, else the first item.
    this.focusInitialItem();

    this.isOpen = true;
  }

  close() {
    if (!this.isOpen) return;

    this.cleanup();

    this.contentTarget.setAttribute('hidden', '');
    this.contentTarget.dataset.state = 'closed';
    this.triggerTarget.setAttribute('aria-expanded', 'false');

    // Return focus to trigger
    this.triggerTarget.focus();

    this.isOpen = false;
  }

  private cleanup() {
    if (this.floatingCleanup) {
      this.floatingCleanup();
      this.floatingCleanup = null;
    }
    if (this.dismissCleanup) {
      this.dismissCleanup();
      this.dismissCleanup = null;
    }
  }

  // Keyboard navigation on trigger
  triggerKeydown(event: KeyboardEvent) {
    switch (event.key) {
      case 'ArrowDown':
      case 'ArrowUp':
        event.preventDefault();
        this.open();
        // After open, focus the appropriate item
        if (event.key === 'ArrowDown') {
          this.focusFirstItem();
        } else {
          this.focusLastItem();
        }
        break;
      case 'Enter':
      case ' ':
        event.preventDefault();
        this.open();
        this.focusFirstItem();
        break;
    }
  }

  // Keyboard navigation within menu
  contentKeydown(event: KeyboardEvent) {
    const items = this.enabledItems;
    const currentIndex = items.indexOf(document.activeElement as HTMLElement);

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.focusNextItem(items, currentIndex);
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.focusPreviousItem(items, currentIndex);
        break;
      case 'Home':
        event.preventDefault();
        this.focusFirstItem();
        break;
      case 'End':
        event.preventDefault();
        this.focusLastItem();
        break;
      case 'Tab':
        // Close menu on Tab, let default tab behavior continue
        this.close();
        break;
      case 'Enter':
      case ' ':
        // Activate the focused item
        event.preventDefault();
        (document.activeElement as HTMLElement)?.click();
        break;
    }
  }

  private get enabledItems(): HTMLElement[] {
    return Array.from(
      this.contentTarget.querySelectorAll('[data-ui--menu-target="item"]:not([data-disabled])')
    ) as HTMLElement[];
  }

  // WAI-ARIA: opening a menu that contains a checked menuitemradio /
  // menuitemcheckbox should move focus to that item rather than the first.
  private focusInitialItem() {
    const checked = this.enabledItems.find(
      (item) => item.getAttribute('aria-checked') === 'true',
    );
    if (checked) {
      checked.focus();
      return;
    }
    this.focusFirstItem();
  }

  private focusFirstItem() {
    const items = this.enabledItems;
    if (items.length > 0) {
      items[0]?.focus();
    }
  }

  private focusLastItem() {
    const items = this.enabledItems;
    if (items.length > 0) {
      items[items.length - 1]?.focus();
    }
  }

  private focusNextItem(items: HTMLElement[], currentIndex: number) {
    if (items.length === 0) return;
    const nextIndex = currentIndex >= 0 && currentIndex < items.length - 1 ? currentIndex + 1 : 0;
    items[nextIndex]?.focus();
  }

  private focusPreviousItem(items: HTMLElement[], currentIndex: number) {
    if (items.length === 0) return;
    const prevIndex = currentIndex > 0 ? currentIndex - 1 : items.length - 1;
    items[prevIndex]?.focus();
  }

  private getPlacement(): Placement {
    const side = this.contentTarget.dataset.side || 'bottom';
    const align = this.contentTarget.dataset.align || 'start';

    if (align === 'center') {
      return side as Placement;
    }

    return `${side}-${align}` as Placement;
  }
}
