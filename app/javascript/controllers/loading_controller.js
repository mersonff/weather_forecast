import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  start() {
    this.originalLabel = this.buttonTarget.value
    this.buttonTarget.disabled = true
    this.buttonTarget.value = "Loading…"
  }

  end() {
    this.buttonTarget.disabled = false
    this.buttonTarget.value = this.originalLabel
  }
}
