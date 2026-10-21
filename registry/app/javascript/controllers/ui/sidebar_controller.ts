import { Controller } from '@hotwired/stimulus';

type SidebarState = 'collapsed' | 'expanded';
type CollapsibleType = 'icon' | 'none';

export default class extends Controller<HTMLElement> {
  static targets = ['sidebar', 'trigger'];

  declare readonly hasSidebarTarget: boolean;
  declare readonly hasTriggerTarget: boolean;
  declare readonly sidebarTarget: HTMLElement;
  declare readonly triggerTargets: HTMLElement[];

  connect() {
    if (!this.hasSidebarTarget) return;

    const savedState = localStorage.getItem('ui-sidebar-state') as SidebarState | null;
    const savedCollapsible = localStorage.getItem('ui-sidebar-collapsible') as CollapsibleType | null;

    if (savedState && savedCollapsible) {
      this.setSidebarState(savedState);
      this.setSidebarCollapsibleType(savedCollapsible);
    }

    this.syncTriggers();
  }

  toggle() {
    if (!this.hasSidebarTarget) return;

    if (this.sidebarState() === 'collapsed') {
      this.setSidebarState('expanded');
      this.setSidebarCollapsibleType('none');
    } else {
      this.setSidebarState('collapsed');
      this.setSidebarCollapsibleType('icon');
    }

    this.syncTriggers();
  }

  private sidebarState(): SidebarState {
    return (this.sidebarTarget.getAttribute('data-state') as SidebarState) || 'expanded';
  }

  private setSidebarState(state: SidebarState) {
    localStorage.setItem('ui-sidebar-state', state);
    this.sidebarTarget.setAttribute('data-state', state);
  }

  private setSidebarCollapsibleType(type: CollapsibleType) {
    localStorage.setItem('ui-sidebar-collapsible', type);
    this.sidebarTarget.setAttribute('data-collapsible', type);
  }

  private syncTriggers() {
    if (!this.hasTriggerTarget) return;

    const expanded = this.sidebarState() !== 'collapsed';
    this.triggerTargets.forEach((trigger) => {
      trigger.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    });
  }
}
