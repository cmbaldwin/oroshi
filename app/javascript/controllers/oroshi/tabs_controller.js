import { Controller } from "@hotwired/stimulus";

/**
 * Tabs Controller - A Turbo-friendly replacement for Bootstrap's tabs/pills data-api
 *
 * Usage:
 *   <div data-controller="oroshi--tabs">
 *     <ul class="nav nav-pills">
 *       <li class="nav-item">
 *         <button class="nav-link active"
 *                 data-oroshi--tabs-target="tab"
 *                 data-action="click->oroshi--tabs#select"
 *                 data-tab-id="main">Main</button>
 *       </li>
 *       <li class="nav-item">
 *         <button class="nav-link"
 *                 data-oroshi--tabs-target="tab"
 *                 data-action="click->oroshi--tabs#select"
 *                 data-tab-id="settings">Settings</button>
 *       </li>
 *     </ul>
 *     <div class="tab-content">
 *       <div class="tab-pane fade show active"
 *            data-oroshi--tabs-target="panel"
 *            data-panel-id="main">Main content</div>
 *       <div class="tab-pane fade"
 *            data-oroshi--tabs-target="panel"
 *            data-panel-id="settings">Settings content</div>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["tab", "panel"];

  connect() {
    // Ensure the initial state is consistent
    this.syncState();
  }

  /**
   * Select a tab when clicked
   */
  select(event) {
    event.preventDefault();
    const clickedTab = event.currentTarget;
    const tabId = clickedTab.dataset.tabId;

    this.activateTab(tabId);
  }

  /**
   * Activate a specific tab by its ID
   */
  activateTab(tabId) {
    // Deactivate all tabs
    this.tabTargets.forEach(tab => {
      tab.classList.remove("active");
      tab.setAttribute("aria-selected", "false");
    });

    // Deactivate all panels
    this.panelTargets.forEach(panel => {
      panel.classList.remove("show", "active");
    });

    // Activate the selected tab
    const selectedTab = this.tabTargets.find(tab => tab.dataset.tabId === tabId);
    if (selectedTab) {
      selectedTab.classList.add("active");
      selectedTab.setAttribute("aria-selected", "true");
    }

    // Activate the selected panel
    const selectedPanel = this.panelTargets.find(panel => panel.dataset.panelId === tabId);
    if (selectedPanel) {
      selectedPanel.classList.add("show", "active");
    }
  }

  /**
   * Sync the state to ensure tabs and panels are consistent
   */
  syncState() {
    const activeTab = this.tabTargets.find(tab => tab.classList.contains("active"));
    if (activeTab) {
      const tabId = activeTab.dataset.tabId;
      this.activateTab(tabId);
    }
  }
}
