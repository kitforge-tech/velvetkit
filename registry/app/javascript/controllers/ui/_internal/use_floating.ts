// frozen_string_literal: true

import {
  computePosition,
  autoUpdate,
  offset,
  flip,
  shift,
  arrow,
  type Placement,
  type Middleware,
} from '@floating-ui/dom';

interface UseFloatingOptions {
  placement?: Placement;
  offset?: number;
  flip?: boolean;
  shift?: boolean;
  arrow?: HTMLElement | null;
  /** 'fixed' escapes scrolling or clipped ancestors, such as a drawer. */
  strategy?: 'absolute' | 'fixed';
}

interface UseFloatingReturn {
  update: () => void;
  destroy: () => void;
}

const STATIC_SIDES: Record<string, string> = {
  top: 'bottom',
  right: 'left',
  bottom: 'top',
  left: 'right',
};

/**
 * Floating UI wrapper for positioning floating elements relative to a reference.
 * Used by Tooltip, Popover, and Dropdown components.
 */
export function useFloating(
  reference: HTMLElement,
  floating: HTMLElement,
  options: UseFloatingOptions = {}
): UseFloatingReturn {
  const {
    placement = 'top',
    offset: offsetValue = 8,
    flip: enableFlip = true,
    shift: enableShift = true,
    arrow: arrowElement,
    strategy = 'absolute',
  } = options;

  const middleware: Middleware[] = [];

  if (offsetValue) {
    middleware.push(offset(offsetValue));
  }

  if (enableFlip) {
    middleware.push(flip());
  }

  if (enableShift) {
    middleware.push(shift({ padding: 8 }));
  }

  if (arrowElement) {
    middleware.push(arrow({ element: arrowElement }));
  }

  const cleanup = autoUpdate(reference, floating, () => {
    computePosition(reference, floating, {
      placement,
      strategy,
      middleware,
    }).then(({ x, y, placement: finalPlacement, middlewareData }) => {
      Object.assign(floating.style, {
        left: `${x}px`,
        top: `${y}px`,
        position: strategy,
      });

      // Position arrow if present
      if (arrowElement && middlewareData.arrow) {
        const { x: arrowX, y: arrowY } = middlewareData.arrow;
        const basePlacement = finalPlacement.split('-')[0];
        const staticSide = basePlacement ? STATIC_SIDES[basePlacement] : undefined;

        if (staticSide) {
          // Clear the side a flip left behind, and tell the arrow which way
          // it now points so its borders follow.
          Object.assign(arrowElement.style, {
            left: arrowX != null ? `${arrowX}px` : '',
            top: arrowY != null ? `${arrowY}px` : '',
            right: '',
            bottom: '',
            [staticSide]: '-4px',
          });
          arrowElement.dataset.side = basePlacement;
        }
      }
    });
  });

  return {
    update: () => {},
    destroy: cleanup,
  };
}

export type { Placement };
