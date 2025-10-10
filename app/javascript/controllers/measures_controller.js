import { Controller } from "@hotwired/stimulus";
import ky from "ky";
import * as v from "valibot";

const CHAR_CHANGED = "characteristicvaluechanged"; // cSpell:words characteristicvaluechanged
const GATT_DISCONNECTED = "gattserverdisconnected"; // cSpell:words gattserverdisconnected

const avgWindowSize = 10;

/**
 * @type {{
 * OPEN: "open",
 * IN_PROCESS: "in_process",
 * WAITING: "waiting",
 * COMPLETED: "completed",
 * CLOSED: "closed"
 * }}
 */
const STATES = {
    OPEN: "open",
    IN_PROCESS: "in_process",
    WAITING: "waiting",
    COMPLETED: "completed",
    CLOSED: "closed",
};

const StatesSchema = v.enum(STATES);

/**
 * @type {{
 * PENDING: "pending",
 * PREDICTED: "predicted",
 * VALIDATED: "validated",
 * ANOMALY: "anomaly"
 * }}
 */
const STATUS = {
    PENDING: "pending",
    PREDICTED: "predicted",
    VALIDATED: "validated",
    ANOMALY: "anomaly",
};

const StatusSchema = v.enum(STATUS);

/**
 * @typedef {v.InferOutput<typeof StatusSchema>} Status
 */

const MeasurementSchema = v.intersect([
    v.object({
        id: v.number(),
        turbidity: v.number(),
    }),
    v.union([
        v.object({
            status: v.literal(STATUS.PENDING),
        }),
        v.object({
            predicted_bod: v.number(),
            predicted_cod: v.number(),
            status: v.literal(STATUS.PREDICTED),
        }),
    ]),
]);

/**
 * BLEで送られてくるペイロードのスキーマ
 */
const BLEPayloadSchema = v.object({
    turbidity: v.number(),
});

/**
 * @typedef {v.InferOutput<typeof MeasurementSchema>} Measurement
 */

const MeasurementStatusSchema = v.object({
    id: v.number(),
    status: StatusSchema,
});

/**
 * @typedef {v.InferOutput<typeof MeasurementStatusSchema>} MeasurementStatus
 */

// Connects to data-controller="measures"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    static values = {
        serviceUuid: String,
        charUuid: String,
        bodUpperLimit: String,
    };

    static targets = [
        "modal",
        "in-process",
        "waiting",
        "completed",
        "result",
        "bod",
        "cod",
        "progress",
        "progressLabel",
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
     * @type {AbortController | null}
     */
    bleAbortController = null;

    /**
     * @type { number }
     */
    measurementId = 0;

    /**
     * ポーリング中フラグ
     *
     * @type {boolean}
     */
    _isPolling = false;

    /**
     * 切断処理中フラグ（再入防止）
     * @type {boolean}
     */
    _isDisconnecting = false;

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

            const prog = this.getTarget("progress");
            const label = this.getTarget("progressLabel");
            prog.style.width = "0%";
            prog.setAttribute("aria-valuenow", "0");
            label.textContent = `0 / ${avgWindowSize}`;
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
        this.measurementId = 0;

        this.changeState(STATES.IN_PROCESS);

        await this.connectToBLEDevice();
    }

    /**
     * キャンセルボタンが押された
     */
    async cancelEstimation() {
        // 停止フラグ
        this._isPolling = false;

        // BLE を切断
        await this.disconnectBLE();

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

    async connectToBLEDevice() {
        try {
            if (!navigator.bluetooth) {
                throw new Error("このブラウザーはサポートしていません。");
            }

            this.bleAbortController = new AbortController();
            const { signal } = this.bleAbortController;

            const ble = await navigator.bluetooth.requestDevice({
                // @ts-ignore
                filters: [{ services: [this.serviceUuidValue] }],
            });

            if (!ble.gatt) {
                throw new Error("GATTサーバーに接続できません。");
            }

            // 保存しておく
            this.device = ble;

            // 切断ハンドラをセット
            this.device.addEventListener(
                GATT_DISCONNECTED,
                this.handleDisconnect.bind(this),
                { signal } // AbortControllerのsignalを渡す
            );

            const server = await ble.gatt.connect();
            this.server = server;

            // @ts-ignore
            const service = await server.getPrimaryService(this.serviceUuidValue);
            // @ts-ignore
            const char = await service.getCharacteristic(this.charUuidValue);

            // 通知開始
            await char.startNotifications();

            char.addEventListener(CHAR_CHANGED, this.handleBLEData.bind(this), {
                signal,
            });

            // 保存
            this.characteristic = char;
        } catch (error) {
            console.error("Error in connectToBLEDevice:", error);
            await this.disconnectBLE();
            alert("BLEデバイスへの接続中にエラーが発生しました。");
            this.changeState(STATES.CLOSED);
        }
    }

    /**
     * BLE 切断時に呼ばれる
     *
     * @param {Event} _ev
     */
    handleDisconnect(_ev) {
        // 切断処理が進行中なら無視
        if (this._isDisconnecting) {
            return;
        }

        // 測定中に切断されたらユーザーに知らせてモーダルを閉じる
        if (this.state === STATES.IN_PROCESS) {
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
        // 再入防止
        if (this._isDisconnecting) return;
        this._isDisconnecting = true;

        try {
            // AbortControllerでイベントリスナーを一括解除
            this.bleAbortController?.abort();

            // server の切断
            if (this.server && this.server.connected) {
                this.server.disconnect();
            }
        } catch (e) {
            console.error("Error during BLE disconnect:", e);
        } finally {
            // クリーンアップ: オブジェクト参照を解放
            this.characteristic = null;
            this.server = null;
            this.device = null;
            this.bleAbortController = null;
            // 切断処理完了後にフラグを戻す
            this._isDisconnecting = false;
        }
    }

    /**
     * @param {Event} event
     */
    async handleBLEData(event) {
        try {
            const possible =
                /** @type {any} */ (event?.target)?.value ??
                /** @type {any} */ (event?.currentTarget)?.value;
            if (!possible) {
                console.warn("BLEのペイロードが空です。");
                return;
            }

            let decoded = null;

            // DataView の場合
            if (
                typeof DataView !== "undefined" &&
                possible instanceof DataView
            ) {
                const bytes = new Uint8Array(
                    possible.buffer,
                    possible.byteOffset,
                    possible.byteLength
                );
                decoded = new TextDecoder().decode(bytes);
            } else if (possible instanceof ArrayBuffer) {
                decoded = new TextDecoder().decode(new Uint8Array(possible));
            } else if (ArrayBuffer.isView && ArrayBuffer.isView(possible)) {
                // e.g. Uint8Array
                const bytes = new Uint8Array(
                    possible.buffer,
                    possible.byteOffset,
                    possible.byteLength
                );
                decoded = new TextDecoder().decode(bytes);
            } else if (typeof possible === "string") {
                decoded = possible;
            } else {
                // 最後の手段: try to coerce to string
                try {
                    decoded = String(possible);
                } catch (e) {
                    console.warn("Unable to decode BLE payload", e);
                    return;
                }
            }

            console.log("Received value:", decoded);

            let json;
            try {
                json = JSON.parse(decoded);
            } catch (e) {
                console.warn("Received non-JSON BLE payload, ignoring", e);
                return;
            }

            let payload;
            try {
                payload = v.parse(BLEPayloadSchema, json);
            } catch (e) {
                console.warn("BLE payload validation failed, ignoring", e);
                return;
            }

            const turbidity = payload.turbidity;

            if (!Number.isFinite(turbidity)) {
                console.warn("turbidity is not a finite number", turbidity);
                return;
            }

            this.turbidities.push(turbidity);

            const prog = this.getTarget("progress");
            const label = this.getTarget("progressLabel");

            const count = Math.min(this.turbidities.length, avgWindowSize);
            const pct = Math.round((count / avgWindowSize) * 100);

            prog.style.width = `${pct}%`;
            prog.setAttribute("aria-valuenow", String(pct));
            label.textContent = `${count} / ${avgWindowSize}`;

            if (this.turbidities.length >= avgWindowSize) {
                prog.style.width = `100%`;
                prog.setAttribute("aria-valuenow", "100");
                label.textContent = `${avgWindowSize} / ${avgWindowSize}`;

                setTimeout(() => this.completeEstimation(), 350);
            }
        } catch (e) {
            console.error("Unhandled error in handleBLEData:", e);
        }
    }

    async completeEstimation() {
        const sum = this.turbidities.reduce((a, b) => a + b, 0);
        const avg = sum / this.turbidities.length;
        console.log("Average turbidity:", avg);
        // 切断してからサーバーへ送信
        await this.disconnectBLE();

        try {
            await createMeasurement(avg).then((measurement) => {
                this.measurementId = measurement.id;
            });
            this.changeState(STATES.WAITING);

            this._isPolling = true;

            const maxAttempts = 12;
            let attempts = 0;
            while (this._isPolling && attempts < maxAttempts) {
                await new Promise((resolve) => setTimeout(resolve, 5000));

                const status = await getStatus(this.measurementId);

                if (status === STATUS.PENDING) {
                    attempts += 1;
                    continue;
                }

                const measurement = await getMeasurement(this.measurementId);
                if (measurement.status === STATUS.PENDING) continue;

                this.setBodValue(measurement.predicted_bod);
                this.setCodValue(measurement.predicted_cod);

                // @ts-ignore
                if (measurement.predicted_bod > this.bodUpperLimitValue) {
                    this.setResultMessage("茹で汁の水質が基準値を超えました。");
                    this.setResultCareful(true);
                } else {
                    this.setResultMessage("茹で汁の水質は綺麗です。");
                    this.setResultCareful(false);
                }

                this.changeState(STATES.COMPLETED);
                this._isPolling = false;
                return;
            }

            if (this._isPolling) {
                alert("結果取得がタイムアウトしました。後で確認してください。");
                this.changeState(STATES.CLOSED);
            }
        } finally {
            this._isPolling = false;
        }
    }
}

/**
 * CSRFトークンを取得する
 *
 * @returns {string}
 */
function getCSRFToken() {
    return (
        document
            .querySelector('meta[name="csrf-token"]')
            ?.getAttribute("content") ?? ""
    );
}

/**
 * 測定結果を保存する
 *
 * @param {number} turbidity
 * @returns {Promise<Measurement>}
 */
async function createMeasurement(turbidity) {
    if (typeof turbidity !== "number" || turbidity < 0) {
        alert("無効な値です");
        throw new Error("無効な値です");
    }

    const data = await ky.post("/measurements", {
        credentials: "include",
        headers: { "X-CSRF-Token": getCSRFToken() },
        json: { measurement: { turbidity } },
    });

    const json = await data.json();
    const parsed = v.parse(MeasurementSchema, json);

    return parsed;
}

/**
 *
 * @param {number} measurementId
 * @returns {Promise<Measurement>}
 */
async function getMeasurement(measurementId) {
    const res = await ky.get(`/measurements/${measurementId}`, {
        credentials: "include",
        headers: { "X-CSRF-Token": getCSRFToken() },
    });
    const json = await res.json();
    const parsed = v.parse(MeasurementSchema, json);

    return parsed;
}

/**
 * 測定結果のステータスを確認する
 *
 * @param {number} measurementId
 * @returns {Promise<Status>}
 */
async function getStatus(measurementId) {
    const res = await ky.get(`/measurements/${measurementId}/status`, {
        credentials: "include",
        headers: { "X-CSRF-Token": getCSRFToken() },
    });
    const json = await res.json();
    const parsed = v.parse(MeasurementStatusSchema, json);

    return parsed.status;
}
