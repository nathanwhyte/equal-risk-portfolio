import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tickers"
export default class extends Controller {
  static targets = ["selected"];
  static values = { selected: Array, id: String };

  initialize() {
    this.selected = this.selectedValue;
  }

  async selectedValueChanged() {
    console.log("selectedValueChanged");
    console.log(this.selectedValue);

    const params = new URLSearchParams({
      portfolio_id: this.idValue,
      tickers: this.selectedValue,
    });

    const response = await fetch(`/search/selected?${params}`, {
      method: "GET",
    });

    const html = await response.text();

    const template = document.createElement("template");
    template.innerHTML = html.trim();
    this.selectedTarget.replaceChildren(template.content);
  }

  toggle(event) {
    const ticker = event.params.tckr;

    if (this.selectedValue.includes(ticker)) {
      this.selected.splice(this.selectedValue.indexOf(ticker), 1);
    } else {
      this.selected.push(ticker);
    }

    // workaround, selectedValue doesn't seem to update unless re-assigned
    this.selectedValue = this.selected;
  }

  submit() {
    console.log(this.selectedValue);
  }
}
