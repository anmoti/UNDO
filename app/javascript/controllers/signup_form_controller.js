// @ts-nocheck
import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="signup-form"
export default class extends Controller {
    static targets = ["title"];

    connect() {
        console.log("Signup form controller connected");
    }

    updateTitle(event) {
        const isCompany = event.target.value === "false";

        if (this.hasTitleTarget) {
            if (isCompany) {
                this.titleTarget.textContent = "企業アカウントの登録";
            } else {
                this.titleTarget.textContent = "サインアップ";
            }
        }
    }
}
