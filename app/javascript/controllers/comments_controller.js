import { Controller } from "@hotwired/stimulus";

/** @import { Context } from "@hotwired/stimulus"  */

const EVENTS = {
    SHOW: "comment:show",
};

// Connects to data-controller="comments"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    boundShow = this.show.bind(this);

    connect() {
        console.log("Comments controller connected");

        // 初期状態では非表示
        this.hide();

        window.addEventListener(EVENTS.SHOW, this.boundShow);
    }

    disconnect() {
        window.removeEventListener(EVENTS.SHOW, this.boundShow);
    }

    show() {
        this.element.classList.remove("hidden");
    }

    hide() {
        this.element.classList.add("hidden");
    }
}

export function triggerShowComments() {
    const event = new Event(EVENTS.SHOW);
    window.dispatchEvent(event);
}
