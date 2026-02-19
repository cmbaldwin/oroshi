import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    this.buildIndex()
  }

  buildIndex() {
    this.entries = []
    document.querySelectorAll(".doc-sidebar .nav-link").forEach(link => {
      this.entries.push({
        text: link.textContent.trim().toLowerCase(),
        label: link.textContent.trim(),
        href: link.href
      })
    })
  }

  search() {
    const query = this.inputTarget.value.trim().toLowerCase()

    if (query.length < 2) {
      this.resultsTarget.style.display = "none"
      this.resultsTarget.innerHTML = ""
      return
    }

    const matches = this.entries.filter(entry => entry.text.includes(query))

    if (matches.length === 0) {
      this.resultsTarget.style.display = "block"
      this.resultsTarget.innerHTML = '<div class="p-2 text-muted small">No results</div>'
      return
    }

    this.resultsTarget.style.display = "block"
    this.resultsTarget.innerHTML = matches.map(match =>
      `<a href="${match.href}" class="d-block p-2 text-decoration-none border-bottom small">${match.label}</a>`
    ).join("")
  }
}
