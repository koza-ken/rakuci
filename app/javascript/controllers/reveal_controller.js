import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    activeClass: { type: String, default: "animate-fade-in-up" },
    once: { type: Boolean, default: true },
    threshold: { type: Number, default: 0.18 },
    delay: { type: Number, default: 240 },
  };

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => entries.forEach((entry) => this.handle(entry)),
      { threshold: this.thresholdValue }
    );
    this.observer.observe(this.element);
  }

  disconnect() {
    if (this.timeoutId) clearTimeout(this.timeoutId);
    if (this.observer) this.observer.disconnect();
  }

  handle(entry) {
    if (!entry.isIntersecting) return;

    if (this.timeoutId) return;

    this.timeoutId = setTimeout(() => {
      this.activate();
    }, this.delayValue);
  }

  activate() {
    this.element.classList.add(this.activeClassValue);
    this.element.classList.remove("opacity-0");

    if (this.onceValue) {
      this.observer.unobserve(this.element);
    }
    this.timeoutId = null;
  }
}
