// @ts-nocheck
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="user-menu"
export default class extends Controller {
    static targets = ["menu"]

    toggle(event) {
        event.stopPropagation()
        this.menuTarget.classList.toggle("user-menu--open")
    }

    close(event) {
        // メニュー外をクリックしたら閉じる
        if (!this.element.contains(event.target)) {
            this.menuTarget.classList.remove("user-menu--open")
        }
    }

    disconnect() {
        if (this.hasMenuTarget) {
            this.menuTarget.classList.remove("user-menu--open")
        }
    }
}
