import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { timeout: Number } // Keep the static values declaration

    connect() {
        // Read timeout from data attribute (data-timeout) or default to 5000ms
        const el = /** @type {HTMLElement} */ (this.element)
        const t = parseInt(el.dataset.timeout || '5000', 10)
        this._timer = setTimeout(() => this.fadeAndRemove(), t)
    }

    disconnect() {
        if (this._timer) clearTimeout(this._timer)
    }
    /**
    * @param {{ currentTarget: any; }} event
    */
    close(event) {
        const btn = /** @type {HTMLElement} */ (event.currentTarget)
        const flash = /** @type {HTMLElement | null} */ (btn.closest('.flash'))
        if (flash) this._removeElement(flash)
    }

    fadeAndRemove() {
        this._removeElement(/** @type {HTMLElement} */(this.element))
    }

    /**
     * @param {HTMLElement | null} el
     */
    _removeElement(el) {
        if (!el) return
        el.classList.add('flash--closing')
        // match CSS transition duration (300ms) before removing
        setTimeout(() => el.remove(), 320)
    }
    /**
     * @param {HTMLElement | null} el
     */
}
