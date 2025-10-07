import { Controller } from "@hotwired/stimulus";
import debounced from "debounced";

debounced.initialize(["input"], { wait: 300 });

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["query", "results"];
  static values = { id: String };

  async tickers(event) {
    event.preventDefault();

    // Return early if the query is empty
    if (!this.queryTarget.value.trim()) {
      const template = document.createElement("template");
      this.resultsTarget.replaceChildren(template.content);
      return;
    }

    const params = new URLSearchParams({
      query: this.queryTarget.value,
      portfolio_id: this.idValue,
    });

    const response = await fetch(`/search/tickers?${params}`, {
      method: "GET",
    });

    const html = await response.text();

    // swap the HTML directly to avoid dangerous innerHTML use
    const template = document.createElement("template");
    template.innerHTML = html.trim();
    this.resultsTarget.replaceChildren(template.content);
  }
}
