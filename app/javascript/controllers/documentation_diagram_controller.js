import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { definition: String }

  async connect() {
    try {
      const { default: mermaid } = await import("https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs")
      mermaid.initialize({ startOnLoad: false, theme: "default" })

      const container = this.element.querySelector(".mermaid")
      if (container && this.definitionValue) {
        const { svg } = await mermaid.render(`mermaid-${Math.random().toString(36).slice(2)}`, this.definitionValue)
        container.innerHTML = svg
      }
    } catch (error) {
      console.warn("Mermaid diagram rendering failed:", error)
      const container = this.element.querySelector(".mermaid")
      if (container) {
        container.innerHTML = `<pre class="bg-light p-3 rounded"><code>${this.definitionValue}</code></pre>`
      }
    }
  }
}
