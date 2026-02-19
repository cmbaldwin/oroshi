import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { noResults: String }

  connect() {
    this.buildIndex()
    this.selectedIndex = -1
  }

  buildIndex() {
    this.entries = []
    let currentSection = null

    document.querySelectorAll(".doc-sidebar nav > *").forEach(el => {
      if (el.classList.contains("nav-section")) {
        currentSection = el.textContent.trim()
      } else if (el.classList.contains("nav-link")) {
        this.entries.push({
          text: el.textContent.trim().toLowerCase(),
          label: el.textContent.trim(),
          href: el.href,
          section: currentSection,
          isSubpage: el.classList.contains("ps-4")
        })
      }
    })
  }

  search() {
    const query = this.inputTarget.value.trim().toLowerCase()
    this.selectedIndex = -1

    if (query.length < 2) {
      this.hide()
      return
    }

    const matches = this.entries.filter(entry => entry.text.includes(query))

    if (matches.length === 0) {
      this.resultsTarget.style.display = "block"
      const noResultsText = this.hasNoResultsValue ? this.noResultsValue : "No results"
      this.resultsTarget.innerHTML = `<div class="p-2 text-muted small">${noResultsText}</div>`
      return
    }

    this.resultsTarget.style.display = "block"
    this.resultsTarget.innerHTML = matches.map((match, i) => {
      const sectionBadge = match.section && match.isSubpage
        ? `<span class="badge bg-light text-muted ms-1" style="font-size: 0.65rem;">${match.section}</span>`
        : ""
      return `<a href="${match.href}"
                class="d-block p-2 text-decoration-none border-bottom small doc-search-result"
                data-index="${i}">${match.label}${sectionBadge}</a>`
    }).join("")
  }

  keydown(event) {
    const results = this.resultsTarget.querySelectorAll(".doc-search-result")
    if (results.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.selectedIndex = Math.min(this.selectedIndex + 1, results.length - 1)
      this.highlightResult(results)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
      this.highlightResult(results)
    } else if (event.key === "Enter" && this.selectedIndex >= 0) {
      event.preventDefault()
      results[this.selectedIndex].click()
    } else if (event.key === "Escape") {
      this.hide()
      this.inputTarget.blur()
    }
  }

  highlightResult(results) {
    results.forEach((r, i) => {
      r.style.background = i === this.selectedIndex ? "#e9ecef" : ""
    })
    if (this.selectedIndex >= 0) {
      results[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  hide() {
    this.resultsTarget.style.display = "none"
    this.resultsTarget.innerHTML = ""
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}
