import { Controller } from "@hotwired/stimulus";

const EVENTS = {
    SHOW: "comment:show",
};

// Connects to data-controller="comments"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    connect() {
        console.log("Comments controller connected");

        // 初期状態では非表示
        this.hide();

        window.addEventListener(EVENTS.SHOW, this.show.bind(this));
    }

    disconnect() {
        window.removeEventListener(EVENTS.SHOW, this.show.bind(this));
    }

    show() {
        this.element.style.display = "block";
    }

    hide() {
        this.element.style.display = "none";
    }
}

export function triggerShowComments() {
    const event = new Event(EVENTS.SHOW);
    window.dispatchEvent(event);
}
