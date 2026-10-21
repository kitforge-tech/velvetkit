import { Controller } from '@hotwired/stimulus';
import { useFloating, type Placement } from './_internal/use_floating.js';
import { useDismiss } from './_internal/use_dismiss.js';

export default class extends Controller<HTMLElement> {
  static targets = ['trigger', 'content', 'arrow'];

  declare readonly triggerTarget: HTMLButtonElement;
  declare readonly contentTarget: HTMLElement;
  declare readonly arrowTarget: HTMLElement;

  private floatingCleanup: (() => void) | null = null;
  private dismissCleanup: (() => void) | null = null;
  private isOpen = false;

  connect() {
    // Initialize with content hidden
    this.close();
  }

  disconnect() {
    this.cleanup();
  }

  toggle() {
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
      offset: 8,
      flip: true,
      shift: true,
      arrow: this.arrowTarget,
    });

    this.floatingCleanup = floating.destroy;

    // Set up dismiss handlers
    const dismiss = useDismiss(this.contentTarget, {
      outsideClick: true,
      escapeKey: true,
      focusOut: true,
      outsideClickExclude: this.triggerTarget,
      onDismiss: (reason) => {
        this.close();
      },
    });
    this.dismissCleanup = dismiss.destroy;

    // Show content
    this.contentTarget.removeAttribute('hidden');
    this.contentTarget.dataset.state = 'open';

    // Update trigger aria
    this.triggerTarget.setAttribute('aria-expanded', 'true');

    // Focus the content for accessibility
    this.contentTarget.focus();

    this.isOpen = true;
  }

  close() {
    if (!this.isOpen) return;

    this.cleanup();

    // Hide content
    this.contentTarget.setAttribute('hidden', '');
    this.contentTarget.dataset.state = 'closed';

    // Update trigger aria
    this.triggerTarget.setAttribute('aria-expanded', 'false');

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

  private getPlacement(): Placement {
    const side = this.contentTarget.dataset.side || 'top';
    const align = this.contentTarget.dataset.align || 'center';

    if (align === 'center') {
      return side as Placement;
    }

    return `${side}-${align}` as Placement;
  }
}
