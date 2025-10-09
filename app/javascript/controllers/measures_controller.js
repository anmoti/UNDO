import { Controller } from "@hotwired/stimulus";
import ky from "ky";
import * as v from "valibot";

const CHAR_CHANGED = "characteristicvaluechanged"; // cSpell:words characteristicvaluechanged
const GATT_DISCONNECTED = "gattserverdisconnected"; // cSpell:words gattserverdisconnected

const SERVICE_UUID = "0696b0a8-b883-4d89-a87c-1f5d5e78d0e9";
const CHAR_UUID = "3d8828a9-e983-4235-a25a-25b741e81893";

const avgWindowSize = 10;
const bodThreshold = 5000;

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

const StatesSchema = v.enum(STATES);

/**
 * @type {{
 *   PENDING: "pending",
 *   PREDICTED: "predicted",
 *   VALIDATED: "validated",
 *   ANOMALY: "anomaly"
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

    async connectToBLEDevice() {
        try {
            if (!navigator.bluetooth) {
                throw new Error("このブラウザーはサポートしていません。");
            }

            const ble = await navigator.bluetooth.requestDevice({
                filters: [{ services: [SERVICE_UUID] }],
            });

            if (!ble.gatt) {
                throw new Error("GATTサーバーに接続できません。");
            }

            // 保存しておく
            this.device = ble;

            // 切断ハンドラをセット
            this.handleDisconnectBound = this.handleDisconnect.bind(this);
            this.device.addEventListener(
                GATT_DISCONNECTED,
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
            char.addEventListener(CHAR_CHANGED, this.handleBLEDataBound);

            // 保存
            this.characteristic = char;
        } catch (error) {
            console.error("Error in connectToBLEDevice:", error);
            this.disconnectBLE();
            alert("BLEデバイスへの接続中にエラーが発生しました。");
        }
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
                    CHAR_CHANGED,
                    this.handleBLEDataBound
                );
            }

            // 意図的に切断するフラグを立てる
            this._intentionalDisconnect = true;

            // device の切断イベントリスナを削除して、disconnect 時のハンドラ呼び出しを防ぐ
            if (this.device && this.handleDisconnectBound) {
                try {
                    this.device.removeEventListener(
                        GATT_DISCONNECTED,
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
            if (this.turbidities.length >= avgWindowSize) {
                this.completeEstimation();
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

                if (measurement.predicted_bod > bodThreshold) {
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
