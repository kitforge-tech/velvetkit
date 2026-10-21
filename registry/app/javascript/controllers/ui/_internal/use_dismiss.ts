/**
 * useDismiss - Handles dismissal interactions for popovers and dialogs
 *
 * Features:
 * - Outside click dismissal
 * - Escape key dismissal
 * - Optional close on focus leaving the element
 */

export interface UseDismissOptions {
  /** Enable dismissal on outside click (default: true) */
  outsideClick?: boolean;
  /** Enable dismissal on Escape key (default: true) */
  escapeKey?: boolean;
  /** Enable dismissal when focus leaves the element (default: false) */
  focusOut?: boolean;
  /** Element(s) to exclude from outside click check (e.g. the trigger button) */
  outsideClickExclude?: HTMLElement | HTMLElement[];
  /** Callback when dismiss is triggered */
  onDismiss?: (reason: 'outside-click' | 'escape-key' | 'focus-out') => void;
}

export interface UseDismissReturn {
  /** Cleanup function to remove event listeners */
  destroy: () => void;
}

/**
 * Hook to handle dismiss interactions for floating elements
 */
export function useDismiss(
  element: HTMLElement,
  options: UseDismissOptions = {}
): UseDismissReturn {
  const { outsideClick = true, escapeKey = true, focusOut = false, onDismiss } = options;

  const handleClickOutside = (event: MouseEvent) => {
    const target = event.target as Node;
    // Check excluded elements (e.g. trigger button)
    const excludes = options.outsideClickExclude ? [options.outsideClickExclude].flat() : [];
    if (excludes.some((el) => el.contains(target))) return;
    if (element && !element.contains(target)) {
      onDismiss?.('outside-click');
    }
  };

  const handleKeyDown = (event: KeyboardEvent) => {
    if (event.key === 'Escape') {
      onDismiss?.('escape-key');
    }
  };

  const handleFocusOut = (event: FocusEvent) => {
    const relatedTarget = event.relatedTarget as Node;
    if (element && !element.contains(relatedTarget)) {
      onDismiss?.('focus-out');
    }
  };

  // Set up event listeners
  if (outsideClick) {
    // Use capture phase to ensure we catch clicks before they bubble
    document.addEventListener('click', handleClickOutside, true);
  }

  if (escapeKey) {
    document.addEventListener('keydown', handleKeyDown);
  }

  if (focusOut) {
    element.addEventListener('focusout', handleFocusOut);
  }

  // Return cleanup function
  return {
    destroy: () => {
      if (outsideClick) {
        document.removeEventListener('click', handleClickOutside, true);
      }
      if (escapeKey) {
        document.removeEventListener('keydown', handleKeyDown);
      }
      if (focusOut) {
        element.removeEventListener('focusout', handleFocusOut);
      }
    },
  };
}
