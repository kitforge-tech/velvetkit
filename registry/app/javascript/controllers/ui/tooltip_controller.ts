import { Controller } from '@hotwired/stimulus';
import { useFloating, type Placement } from './_internal/use_floating.js';

export default class extends Controller<HTMLElement> {
  static targets = ['trigger', 'content', 'arrow'];

  declare readonly triggerTarget: HTMLElement;
  declare readonly contentTarget: HTMLElement;
  declare readonly arrowTarget: HTMLElement;

  private floatingCleanup: (() => void) | null = null;
  private showTimeout: number | null = null;
  private hideTimeout: number | null = null;
  private isVisible = false;

  // Configuration
  private readonly openDelay = 150;
  private readonly closeDelay = 100;

  connect() {
    // Initialize with content hidden
    this.hideContent();
  }

  disconnect() {
    this.clearTimeouts();
    this.cleanupFloating();
  }

  show() {
    this.clearTimeouts();
    this.showTimeout = window.setTimeout(() => {
      this.showContent();
    }, this.openDelay);
  }

  hide() {
    this.clearTimeouts();
    this.hideTimeout = window.setTimeout(() => {
      this.hideContent();
    }, this.closeDelay);
  }

  private showContent() {
    if (this.isVisible) return;

    const placement = this.getPlacement();
    // Offset = visible gap (8) + arrow protrusion (~6: 4px staticSide + ~2px
    // diamond corner from rotate-45). Without this margin the arrow tip hugs
    // the trigger edge and reads as "overlapped".
    const floating = useFloating(this.triggerTarget, this.contentTarget, {
      placement,
      offset: 14,
      flip: true,
      shift: true,
      arrow: this.arrowTarget,
    });

    this.floatingCleanup = floating.destroy;
    this.contentTarget.removeAttribute('hidden');
    this.contentTarget.dataset.state = 'open';
    this.isVisible = true;
  }

  private hideContent() {
    if (!this.isVisible) return;

    this.cleanupFloating();
    this.contentTarget.setAttribute('hidden', '');
    this.contentTarget.dataset.state = 'closed';
    this.isVisible = false;
  }

  private cleanupFloating() {
    if (this.floatingCleanup) {
      this.floatingCleanup();
      this.floatingCleanup = null;
    }
  }

  private clearTimeouts() {
    if (this.showTimeout) {
      clearTimeout(this.showTimeout);
      this.showTimeout = null;
    }
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout);
      this.hideTimeout = null;
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
