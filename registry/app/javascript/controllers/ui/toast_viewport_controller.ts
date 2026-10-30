import { Controller } from '@hotwired/stimulus';

export interface ToastOptions {
  description?: string;
  variant?: 'default' | 'success' | 'destructive' | 'warning' | 'info';
  /** Seconds before it dismisses itself; 0 leaves it until clicked away. */
  duration?: number;
}

/**
 * Pushes a toast from client-side JS, no server round trip. Dispatches an
 * event the toast-viewport controller below listens for; it builds the
 * toast by cloning one of the templates UI::Toast::Viewport renders (one per
 * variant), so a JS-triggered toast is pixel-identical to a server-rendered
 * one and never needs its own copy of the component's styling.
 *
 * Import `toast` from this same controller file, then call it:
 * toast("Saved", { variant: "success" }).
 *
 * For a toast pushed from the server, skip this and append a UI::Toast to
 * UI::Toast::Viewport::ID in a Turbo Stream response instead.
 */
export function toast(title: string, options: ToastOptions = {}) {
  window.dispatchEvent(new CustomEvent<ToastOptions & { title: string }>('toast:show', {
    detail: { title, ...options },
  }));
}

/**
 * UI::Toast::Viewport controller — listens for toast:show and clones the
 * matching variant template into itself. The cloned toast then connects its
 * own ui--toast controller like any other toast, which is what actually
 * drives its auto-dismiss and animations.
 */
export default class extends Controller<HTMLElement> {
  static targets = ['template'];

  declare readonly templateTargets: HTMLTemplateElement[];

  connect() {
    window.addEventListener('toast:show', this.show as EventListener);
  }

  disconnect() {
    window.removeEventListener('toast:show', this.show as EventListener);
  }

  private show = (event: Event) => {
    const detail = (event as CustomEvent<ToastOptions & { title?: string }>).detail || {};
    const template = this.findTemplate(detail.variant);
    if (!template) return;

    const node = template.content.firstElementChild?.cloneNode(true) as HTMLElement | undefined;
    if (!node) return;

    this.fill(node, 'title', detail.title);
    this.fill(node, 'description', detail.description);

    if (detail.duration !== undefined) {
      node.setAttribute('data-ui--toast-duration-value', String(detail.duration * 1000));
    }

    this.element.appendChild(node);
  };

  private findTemplate(variant?: string) {
    return (
      this.templateTargets.find((t) => t.dataset.variant === variant) ||
      this.templateTargets.find((t) => t.dataset.variant === 'default')
    );
  }

  private fill(node: HTMLElement, target: string, text?: string) {
    const el = node.querySelector<HTMLElement>(`[data-ui--toast-target="${target}"]`);
    if (!el) return;
    if (text) {
      el.textContent = text;
    } else {
      el.remove();
    }
  }
}
