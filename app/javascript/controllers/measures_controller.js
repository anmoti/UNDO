import { Controller } from "@hotwired/stimulus";
import ky from "ky";

const SERVICE_UUID = "0696b0a8-b883-4d89-a87c-1f5d5e78d0e9";
const CHARACTERISTIC_UUID = "3d8828a9-e983-4235-a25a-25b741e81893";

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

// Connects to data-controller="measures"
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

    getCSRFToken() {
        return (
            document
                .querySelector('meta[name="csrf-token"]')
                ?.getAttribute("content") ?? ""
        );
    }

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
    async startEstimation() {
        this.changeState(STATES.IN_PROCESS);

        // @ts-ignore
        const ble = await navigator.bluetooth.requestDevice({
            filters: [{ services: [SERVICE_UUID] }],
        });
        const server = await ble.gatt.connect();
        const service = await server.getPrimaryService(SERVICE_UUID);
        const characteristic = await service.getCharacteristic(
            CHARACTERISTIC_UUID
        );
        await characteristic.startNotifications();
        characteristic.addEventListener(
            "characteristicvaluechanged",
            this.handleBLEData.bind(this)
        );
    }

    async handleBLEData(event) {
        const value = new TextDecoder().decode(event.target.value);
        console.log("Received value:", value);
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

    /**
     * 測定結果を保存する
     * @param {number} turbidity
     */
    async createMeasurement(turbidity) {
        const data = await ky.post("/measurements", {
            credentials: "include",
            headers: {
                "X-CSRF-Token": this.getCSRFToken(),
            },
            json: {
                measurement: { turbidity },
            },
        });
        console.log(data);

        return data;
    }
}
