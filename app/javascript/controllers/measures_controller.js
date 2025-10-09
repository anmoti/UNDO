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
     *
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
     *
     * @type {((ev: Event) => any) | null}
     */
    handleBLEDataBound = null;

    /**
     * gattserverdisconnected のバインド済みハンドラ
     *
     * @type {((ev: Event) => any) | null}
     */
    handleDisconnectBound = null;

    /**
     * 意図的に切断中かどうか
     *
     * @type {boolean}
     */
    _intentionalDisconnect = false;

    /**
     * @type { string }
     */
    measurementId = "";

    /**
     * ポーリング中フラグ
     *
     * @type {boolean}
     */
    _isPolling = false;

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
        // 停止フラグ
        this._isPolling = false;

        // BLE を切断
        this.disconnectBLE();

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
     *
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
        const res = await ky.get(`/measurements/${this.measurementId}/status`, {
            credentials: "include",
            headers: {
                "X-CSRF-Token": this.getCSRFToken(),
            },
        });
        const json = await res.json();
        console.log("Status data:", json);
        return json;
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

        // 保存しておく
        this.device = ble;

        // 切断ハンドラをセット
        this.handleDisconnectBound = this.handleDisconnect.bind(this);
        this.device.addEventListener(
            "gattserverdisconnected",
            this.handleDisconnectBound
        );

        const server = await ble.gatt.connect();
        this.server = server;

        const service = await server.getPrimaryService(SERVICE_UUID);
        const char = await service.getCharacteristic(CHAR_UUID);

        // 通知開始
        await char.startNotifications();

        // バインド済みハンドラを保存しておく
        this.handleBLEDataBound = this.handleBLEData.bind(this);
        char.addEventListener(
            "characteristicvaluechanged",
            this.handleBLEDataBound
        );

        // 保存
        this.characteristic = char;
    }

    /**
     * BLE 切断時に呼ばれる
     *
     * @param {Event} _ev
     */
    handleDisconnect(_ev) {
        // 測定中に切断されたらユーザーに知らせてモーダルを閉じる
        if (!this._intentionalDisconnect && this.state === STATES.IN_PROCESS) {
            console.warn("BLE device disconnected during measurement");
            alert("測定中にBLEが切断されました。測定を中止します。");
        }

        // クリーンアップしてモーダルを閉じる
        this.disconnectBLE();
        this.changeState(STATES.CLOSED);
    }

    /**
     * BLE の通知解除と切断を行う
     */
    async disconnectBLE() {
        try {
            if (this.characteristic && this.handleBLEDataBound) {
                this.characteristic.removeEventListener(
                    "characteristicvaluechanged",
                    this.handleBLEDataBound
                );
            }

            // 意図的に切断するフラグを立てる
            this._intentionalDisconnect = true;

            // device の切断イベントリスナを削除して、disconnect 時のハンドラ呼び出しを防ぐ
            if (this.device && this.handleDisconnectBound) {
                try {
                    this.device.removeEventListener(
                        "gattserverdisconnected",
                        this.handleDisconnectBound
                    );
                } catch (e) {
                    // ignore
                }
            }

            if (this.server && this.server.connected) {
                this.server.disconnect();
            }
        } catch (e) {
            console.error("Error during BLE disconnect:", e);
        } finally {
            this.characteristic = null;
            this.server = null;
            this.device = null;
            this.handleBLEDataBound = null;
            this.handleDisconnectBound = null;
            this._intentionalDisconnect = false;
        }
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

                if (this.turbidities.length >= 100) {
                    this.completeEstimation();
                }
            }
        } catch (e) {
            console.error("Error parsing JSON:", e);
        }
    }

    async completeEstimation() {
        const sum = this.turbidities.reduce((a, b) => a + b, 0);
        const avg = sum / this.turbidities.length;
        console.log("Average turbidity:", avg);
        // 切断してからサーバーへ送信
        await this.disconnectBLE();

        const data = await this.createMeasurement(avg);
        const json = await data.json();
        this.measurementId = String(json.id);
        this.changeState(STATES.WAITING);

        // ポーリングで status が predicted になるのを待つ
        this._isPolling = true;
        try {
            const maxAttempts = 60; // 最大 5 分（5s * 60）
            let attempts = 0;
            while (this._isPolling && attempts < maxAttempts) {
                const statusJson = await this.checkStatus();
                if (!statusJson) break;

                const status = statusJson.status;
                if (status !== "pending") {
                    if (typeof statusJson.bod === "number") {
                        this.setBodValue(statusJson.bod);
                    }
                    if (typeof statusJson.cod === "number") {
                        this.setCodValue(statusJson.cod);
                    }
                    if (statusJson.message) {
                        this.setResultMessage(statusJson.message);
                    }
                    this.setResultCareful(!!statusJson.careful);
                    this.changeState(STATES.COMPLETED);
                    this._isPolling = false;
                    return;
                }

                // まだ predicted でなければ待機
                await new Promise((resolve) => setTimeout(resolve, 5000));
                attempts += 1;
            }

            if (this._isPolling) {
                // タイムアウト
                alert("結果取得がタイムアウトしました。後で確認してください。");
                this.changeState(STATES.CLOSED);
            }
        } finally {
            this._isPolling = false;
        }
    }
}
