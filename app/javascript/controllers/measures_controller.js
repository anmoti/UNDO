import { Controller } from "@hotwired/stimulus";

/**
 * @type {{
 *   OPEN: "open",
 *   IN_PROCESS: "in_process",
 *   COMPLETED: "completed",
 *   CLOSED: "closed"
 * }}
 */
const STATES = {
    OPEN: "open",
    IN_PROCESS: "in_process",
    COMPLETED: "completed",
    CLOSED: "closed",
};

// Connects to data-controller="comments"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    static targets = [
        "modal",
        "in-process",
        "completed",
        "result",
        "bod",
        "cod",
    ];

    /**
     * @type {typeof STATES[keyof typeof STATES]}
     */
    state = STATES.CLOSED;

    connect() {
        console.log("Measures controller connected");
        this.changeState(STATES.CLOSED);
    }

    /**
     * 状態を変更する
     *
     * @param {typeof STATES[keyof typeof STATES]} newState
     */
    changeState(newState) {
        this.state = newState;

        if (this.state === STATES.CLOSED) {
            this.getTarget("modal").classList.add("hidden");
        } else {
            this.getTarget("modal").classList.remove("hidden");
        }

        if (this.state === STATES.IN_PROCESS) {
            this.getTarget("in-process").classList.remove("hidden");
        } else {
            this.getTarget("in-process").classList.add("hidden");
        }

        if (this.state === STATES.COMPLETED) {
            this.getTarget("completed").classList.remove("hidden");
        } else {
            this.getTarget("completed").classList.add("hidden");
        }
    }

    /**
     * モーダルを開くボタンが押された
     */
    open() {
        this.changeState(STATES.OPEN);
    }

    /**
     * 測定開始ボタンが押された
     */
    startEstimation() {
        this.changeState(STATES.IN_PROCESS);

        setTimeout(() => {
            this.setBodValue(50);
            this.setCodValue(50);
            this.changeState(STATES.COMPLETED);
        }, 3000);
    }

    /**
     * キャンセルボタンが押された
     */
    cancelEstimation() {
        this.changeState(STATES.CLOSED);
    }

    /**
     * 結果のBOD値をセットする
     *
     * @param {number} value
     */
    setBodValue(value) {
        this.getTarget("bod").textContent = String(value);
    }

    /**
     * 結果のCOD値をセットする
     *
     * @param {number} value
     */
    setCodValue(value) {
        this.getTarget("cod").textContent = String(value);
    }

    /**
     * 指定された名前のターゲットを取得する
     *
     * @param {string} targetName
     */
    getTarget(targetName) {
        const target = this.targets.find(targetName);
        if (!target) {
            throw new Error(`Target ${targetName} not found`);
        }
        return target;
    }
}
