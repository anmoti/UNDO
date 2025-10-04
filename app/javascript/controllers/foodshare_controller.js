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
        const activeUrlPath = this.activeUrlValue;
        //@ts-ignore
        const isActive = currentSrc.includes(activeUrlPath);

        //@ts-ignore
        const newSrc = isActive ? this.inactiveUrlValue : this.activeUrlValue;

        //@ts-ignore
        this.iconTarget.src = newSrc;
    }
}