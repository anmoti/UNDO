import { Controller } from "@hotwired/stimulus";

/** @extends {Controller<HTMLDivElement>} */
export default class FoodshareController extends Controller {
    static targets = ["icon"];
    static values = {
        activeUrl: String,
        inactiveUrl: String,
    };

    /**
     * フードシェア告知ボタンがクリックされたときの処理
     * 
     */
    foodshareChange() {
        //@ts-ignore
        const iconElement = this.iconTarget;
        const currentSrc = iconElement.src;

        //@ts-ignore
        const isActive = currentSrc.includes(this.activeUrlValue);

        let newSrc;
        if (isActive) {
            //@ts-ignore
            newSrc = this.inactiveUrlValue;
        } else {
            //@ts-ignore
            newSrc = this.activeUrlValue;
        }

        //@ts-ignore
        this.iconTarget.src = newSrc;
    }
}