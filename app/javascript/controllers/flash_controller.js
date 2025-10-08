import { Controller } from "@hotwired/stimulus";

/** @extends { Controller<HTMLDivElement> } */
export default class extends Controller {
    static values = { timeout: Number }; // Keep the static values declaration

    /**
     * @returns {Number}
     */
    getTimeoutVal() {
        // @ts-ignore
        if (!this.hasTimeoutValue)
            throw new Error("timeoutValue is not defined");
        // @ts-ignore
        return this.timeoutValue;
    }

    connect() {
        const t = this.getTimeoutVal();
        this._timer = setTimeout(() => this.fadeAndRemove(), t);
    }

    disconnect() {
        if (this._timer) clearTimeout(this._timer);
    }

    /**
     * @param {PointerEvent} event
     */
    close(event) {
        const elem = /** @type {HTMLElement } */ (event.currentTarget);
        const flash = elem.closest(".flash");
        if (flash) this._removeElement(/** @type {HTMLElement} */ (flash));
    }

    fadeAndRemove() {
        this._removeElement(this.element);
    }

    /**
     * @param {HTMLElement | null} el
     */
    _removeElement(el) {
        if (!el) return;
        el.classList.add("flash--closing");
        // match CSS transition duration (300ms) before removing
        setTimeout(() => el.remove(), 320);
    }
}
