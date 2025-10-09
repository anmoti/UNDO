import { Controller } from "@hotwired/stimulus";
import ky from "ky";

const SERVICE_UUID = "0696b0a8-b883-4d89-a87c-1f5d5e78d0e9";
const CHAR_UUID = "3d8828a9-e983-4235-a25a-25b741e81893";

/**
 * @type {{
 *   OPEN: "open",
 *   IN_PROCESS: "in_process",
 *   WAITING: "waiting",
 *   COMPLETED: "completed",
 *   CLOSED: "closed"
 * }}
 */
const STATES = {
    OPEN: "open",
    IN_PROCESS: "in_process",
    WAITING: "waiting",
    COMPLETED: "completed",
    CLOSED: "closed",
};

// Connects to data-controller="measures"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    static targets = [
        "modal",
        "in-process",
        "waiting",
        "completed",
        "result",
        "bod",
        "cod",
    ];

    /**
     * @type {Number[]}
     */
    turbidities = [];

    /**
     * BLE device/server/characteristic references
     * @type { BluetoothDevice | null }
     */
    device = null;

    /**
     * @type { BluetoothRemoteGATTServer | null }
     */
    server = null;

    /**
     * @type { BluetoothRemoteGATTCharacteristic | null }
     */
    characteristic = null;

    /**
     * handleBLEDataのバインド済み関数
     */
    handleBLEDataBound = null;

    /**
     * @type { string }
     */
    measurementId = "";

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

        if (this.state === STATES.WAITING) {
            this.getTarget("waiting").classList.remove("hidden");
        } else {
            this.getTarget("waiting").classList.add("hidden");
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
        // 測定毎にリセット
        this.turbidities = [];
        this.measurementId = "";

        this.changeState(STATES.IN_PROCESS);

        try {
            await this.connectToBLEDevice();
        } catch (error) {
            console.error("Error connecting to BLE device:", error);
            alert("BLEデバイスへの接続中にエラーが発生しました。");
            this.changeState(STATES.CLOSED);
            return;
        }
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
     * 結果のリザルトメッセージをセットする
     *
     * @param {string} message
     */
    setResultMessage(message) {
        this.getTarget("result").textContent = message;
    }

    /**
     *
     * @param {boolean} b
     */
    setResultCareful(b) {
        this.getTarget("result").classList.toggle("careful", b);
    }

    /**
     * 指定された名前のターゲットを取得する
     *
     * @param {string} targetName
     */
    getTarget(targetName) {
        const accessor = `${targetName}Target`;

        // @ts-ignore
        const target = /** @type {HTMLElement} */ (this[accessor]);
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
        const data =
            await /** @type {import("ky").ResponsePromise<{ id: string }>} */ (
                ky.post("/measurements", {
                    credentials: "include",
                    headers: {
                        "X-CSRF-Token": this.getCSRFToken(),
                    },
                    json: {
                        measurement: { turbidity },
                    },
                })
            );
        console.log(data);

        return data;
    }

    async checkStatus() {
        const data = await ky.get(
            `/measurements/${this.measurementId}/status`,
            {
                credentials: "include",
                headers: {
                    "X-CSRF-Token": this.getCSRFToken(),
                },
            }
        );
        const json = await data.json();
        console.log("Status data:", json);
    }

    async connectToBLEDevice() {
        if (!navigator.bluetooth) {
            return {
                error: "Web Bluetooth API がこのブラウザでサポートされていません。",
            };
        }

        const ble = await navigator.bluetooth.requestDevice({
            filters: [{ services: [SERVICE_UUID] }],
        });

        if (!ble.gatt) {
            return { error: "GATT サーバーに接続できません。" };
        }

        const server = await ble.gatt.connect();
        const service = await server.getPrimaryService(SERVICE_UUID);
        const char = await service
            .getCharacteristic(CHAR_UUID)
            .then((c) => c.startNotifications());
        char.addEventListener(
            "characteristicvaluechanged",
            this.handleBLEData.bind(this)
        );
    }

    /**
     * @param {Event} event
     */
    async handleBLEData(event) {
        if (!event.target) {
            throw new Error("No currentTarget in event");
        }

        console.log(event.target);

        // @ts-ignore
        const value = new TextDecoder().decode(event.target.value);
        console.log("Received value:", value);

        try {
            const json = JSON.parse(value);
            const turbidity = json.turbidity;
            if (typeof turbidity === "number") {
                this.turbidities.push(turbidity);
                console.log("Current turbidities:", this.turbidities);
            }

            this.completeEstimation();

            if (this.turbidities.length >= 100) {
                const sum = this.turbidities.reduce((a, b) => a + b, 0);
                const avg = sum / this.turbidities.length;
                console.log("Average turbidity:", avg);

                // this.completeEstimation();
            }
        } catch (e) {
            console.error("Error parsing JSON:", e);
        }
    }

    async completeEstimation() {
        const sum = this.turbidities.reduce((a, b) => a + b, 0);
        const avg = sum / this.turbidities.length;
        console.log("Average turbidity:", avg);

        const data = await this.createMeasurement(avg);
        const json = await data.json();
        this.measurementId = String(json.id);
        this.changeState(STATES.WAITING);

        // while (true) {
        //     await this.checkStatus();
        //     await new Promise((resolve) => setTimeout(resolve, 5000));
        // }

        this.setBodValue(0); // 仮の値
        this.setCodValue(0); // 仮の値
        // this.setResultMessage("茹で汁の水質が基準値を超えました。");
        // this.setResultCareful(true);

        this.changeState(STATES.COMPLETED);
    }
}
