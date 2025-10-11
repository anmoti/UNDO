import { Controller } from "@hotwired/stimulus";
import { Loader } from "@googlemaps/js-api-loader";
import { triggerShowComments, triggerHideComments } from "controllers/comments_controller";

/** @import { Context } from "@hotwired/stimulus"  */

/** Helper to read Google Maps API key from meta tag */
function getGoogleMapsApiKey() {
    /** @type {HTMLMetaElement | null} */
    const meta = document.querySelector('meta[name="google-maps-api-key"]');
    if (!meta) {
        console.warn("Google Maps API key meta tag not found.");
        return "";
    }
    return meta.content;
}

// 香川県範囲 34.2128846,134.065572,10.75z

/** @type {google.maps.MapOptions} */
const mapOptions = {
    mapId: "7a01e92ef6a514a2c6970be6", // Map: undo-main
    center: {
        lat: 34.2128846,
        lng: 134.065572,
    },
    zoom: 10.75,
    disableDefaultUI: true,
};

/**
 * @typedef {Object} ShareInfo
 * @property {string} itemName
 * @property {string} description
 * @property {string} takeDownTime
 * @property {string} photoUrl
 */

/**
 * @typedef {Object} StoreFeature
 * @property {number} id
 * @property {string} name
 * @property {number} lat
 * @property {number} lon
 * @property {string | null | undefined} [openTime]
 * @property {string | null | undefined} [address]
 * @property {boolean | null | undefined} [eco]
 * @property {boolean | null | undefined} [foodshare]
 * @property {ShareInfo | null | undefined} [shareInfo]
 */

// Connects to data-controller="maps"
/** @extends {Controller<HTMLDivElement>} */
export default class MapsController extends Controller {
    /** @type {Loader} */
    loader;

    /** @type {Promise<google.maps.Map>} */
    map;

    /** @type {?google.maps.InfoWindow} */
    infoWindow = null;

    /** @type {Map<number, google.maps.marker.AdvancedMarkerElement>} */
    markers = new Map();

    /** @type {?number} */
    updateMarkersTimeout = null;

    /** @type {Map<number, number>} */
    pendingMarkerTimeouts = new Map();

    static targets = ["icon"];
    static values = {
        ecoIconUrl: String,
        foodshareIconUrl: String,
        stores: Array,
        isCompany: Boolean,
        companyRestrictionMessage: String,
    };

    /**
     * @param  {Context} context
     */
    constructor(context) {
        super(context);

        this.loader = new Loader({
            apiKey: getGoogleMapsApiKey(),
            version: "weekly",
            libraries: ["maps", "marker"],
        });

        this.map = this.loader
            .importLibrary("maps")
            .then(async ({ Map: GMaps }) => {
                const map = new GMaps(this.element, mapOptions);
                console.log("Map initialized:", map);
                return map;
            });
    }

    async connect() {
        console.log("Maps controller connected");

        const map = await this.map;

        await Promise.race([
            new Promise((resolve) => {
                const listener = map.addListener("idle", () => {
                    google.maps.event.removeListener(listener);
                    resolve(undefined);
                });
            }),
            new Promise((resolve) => setTimeout(resolve, 5000))
        ]);


        // 地図の表示領域が変更されたときにマーカーを更新
        map.addListener("bounds_changed", () => {
            this.scheduleUpdateMarkers();
        });

        // 初回のマーカー表示
        await this.updateVisibleMarkers();
    }

    /**
     * マーカー更新をスケジュール（デバウンス処理）
     */
    scheduleUpdateMarkers() {
        if (this.updateMarkersTimeout) {
            clearTimeout(this.updateMarkersTimeout);
        }

        this.updateMarkersTimeout = setTimeout(() => {
            this.updateVisibleMarkers();
        }, 300); // 300ms後に更新
    }

    /**
     * 表示領域内の店舗のみマーカーを表示
     */
    async updateVisibleMarkers() {
        // @ts-ignore Stimulus value accessors are defined at runtime
        const stores = this.hasStoresValue ? this.storesValue : [];

        if (!stores.length) {
            console.info("No store data provided for map markers.");
            return;
        }

        const map = await this.map;
        const bounds = map.getBounds();

        if (!bounds) {
            console.warn("Map bounds not available yet");
            return;
        }

        console.log("Updating markers for current bounds");

        // 表示領域内の店舗を特定
        const visibleStoreIds = new Set();

        for (const store of stores) {
            const lat = Number(store.lat);
            const lon = Number(store.lon);

            if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
                continue;
            }

            const position = { lat, lng: lon };

            // 店舗が表示領域内にあるかチェック
            if (bounds.contains(position)) {
                visibleStoreIds.add(store.id);

                // まだマーカーが作成されていない場合は作成（アニメーション付き）
                if (!this.markers.has(store.id)) {
                    // 既存の保留中タイムアウトを中止
                    if (this.pendingMarkerTimeouts.has(store.id)) {
                        clearTimeout(this.pendingMarkerTimeouts.get(store.id));
                    }

                    // ランダムな遅延を追加して、マーカーが順次表示されるようにする
                    const delay = Math.random() * 300;
                    const timeoutId = setTimeout(() => {
                        if (bounds.contains(position)) {
                            this.createMarker(store, position);
                        }
                        this.pendingMarkerTimeouts.delete(store.id);
                    }, delay);
                    this.pendingMarkerTimeouts.set(store.id, timeoutId);
                }
            }
        }

        // 表示領域外のマーカーをアニメーション付きで削除
        for (const [storeId, marker] of this.markers.entries()) {
            if (!visibleStoreIds.has(storeId)) {
                if (this.pendingMarkerTimeouts.has(storeId)) {
                    clearTimeout(this.pendingMarkerTimeouts.get(storeId));
                    this.pendingMarkerTimeouts.delete(storeId);
                }
                this.removeMarkerWithAnimation(storeId, marker);
            }
        }

        console.log(`Visible markers: ${this.markers.size} / ${stores.length} stores`);
    }

    /**
     * 個別のマーカーを作成
     * @param {StoreFeature} store
     * @param {{lat: number, lng: number}} position
     */
    async createMarker(store, position) {
        const { AdvancedMarkerElement } = await this.loader.importLibrary(
            "marker",
        );
        const map = await this.map;

        // カスタムマーカーアイコンを作成
        const markerIcon = document.createElement("div");
        markerIcon.className = "maps__marker";

        // エコ店舗はマーカー色を緑にする
        if (store.eco) {
            markerIcon.classList.add("maps__marker--eco");
        }

        // シェア情報がある場合、リサイクルマークと残り時間を追加
        if (store.foodshare && store.shareInfo) {
            const shareIndicator = document.createElement("div");
            shareIndicator.className = "maps__marker-share";

            // リサイクルマーク
            const recycleIcon = document.createElement("span");
            recycleIcon.className = "maps__marker-share-icon";
            recycleIcon.textContent = "♻️";
            shareIndicator.appendChild(recycleIcon);

            // 残り時間を計算
            const takeDownTime = new Date(store.shareInfo.takeDownTime);
            const now = new Date();
            const diffMs = takeDownTime.getTime() - now.getTime();
            const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
            const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

            if (diffMs > 0) {
                const timeText = document.createElement("span");
                timeText.className = "maps__marker-share-time";
                timeText.textContent = diffHours > 0 ? `${diffHours}h${diffMinutes}m` : `${diffMinutes}m`;
                shareIndicator.appendChild(timeText);
            }

            markerIcon.appendChild(shareIndicator);
        }

        // マーカーを作成
        const marker = new AdvancedMarkerElement({
            position,
            map,
            title: store.name,
            content: markerIcon,
            gmpClickable: true,
        });

        marker.addListener("click", () => {
            this.showShopInfo(store, marker);
        });

        this.markers.set(store.id, marker);
        console.log(`Marker created for ${store.name}`);
    }

    /**
     * マーカーをアニメーション付きで削除
     * @param {number} storeId
     * @param {google.maps.marker.AdvancedMarkerElement} marker
     */
    removeMarkerWithAnimation(storeId, marker) {
        const markerElement = marker.content;

        if (markerElement instanceof HTMLElement) {
            // 消えるアニメーションを追加
            markerElement.classList.add("maps__marker--disappear");

            // アニメーション完了後にマーカーを削除
            setTimeout(() => {
                marker.map = null;
                if (this.markers.has(storeId)) {
                    this.markers.delete(storeId);
                }
            }, 300); // アニメーション時間と一致
        } else {
            // フォールバック: 即座に削除
            marker.map = null;
            this.markers.delete(storeId);
        }
    }

    /**
     * @param {StoreFeature} shop
     * @param {google.maps.marker.AdvancedMarkerElement} marker
     */
    async showShopInfo(shop, marker) {
        const { InfoWindow } = await this.loader.importLibrary("maps");

        // 既存の情報ウィンドウがあれば閉じる
        if (this.infoWindow) {
            this.infoWindow.close();
        }

        this.infoWindow = new InfoWindow();

        // InfoWindowが閉じられたときにコメント欄も閉じる
        this.infoWindow.addListener("closeclick", () => {
            triggerHideComments();
        });

        // 情報ウィンドウのコンテンツを作成
        const content = document.createElement("div");
        content.className = "maps__info";

        // ヘッダー: タイトル + バッジ群
        const header = document.createElement("div");
        header.className = "maps__info--header";
        const title = document.createElement("h3");
        title.className = "maps__info--title";
        title.textContent = shop.name;
        header.appendChild(title);
        const headerRight = document.createElement("div");
        headerRight.className = "maps__info--header-right";
        const badges = document.createElement("div");
        badges.className = "maps__info--badges";

        if (shop.eco) {
            const EcoOptions = document.createElement("div");
            const ecoImg = new Image(16, 16);
            // @ts-ignore Stimulus value accessors are defined at runtime
            if (this.hasEcoIconUrlValue) {
                // @ts-ignore
                ecoImg.src = this.ecoIconUrlValue;
            }
            EcoOptions.appendChild(ecoImg);
            const ecoDesc = document.createElement("span");
            ecoDesc.textContent = "環境配慮";
            EcoOptions.appendChild(ecoDesc);
            EcoOptions.className = "maps__info--eco";
            badges.appendChild(EcoOptions);
        }
        /** @type {HTMLDivElement | null} */
        let shareDetailEl = null;
        if (shop.foodshare) {
            const foodshareOptions = document.createElement("div");
            const foodshareImg = new Image(16, 16);
            // @ts-ignore Stimulus value accessors are defined at runtime
            if (this.hasFoodshareIconUrlValue) {
                //@ts-ignore
                foodshareImg.src = this.foodshareIconUrlValue;
            }
            foodshareOptions.appendChild(foodshareImg);
            const foodshareDesc = document.createElement("span");
            foodshareDesc.textContent = "フードシェア";
            foodshareOptions.appendChild(foodshareDesc);
            foodshareOptions.className = "maps__info--foodshare";
            badges.appendChild(foodshareOptions);

            // シェア詳細情報を追加
            if (shop.shareInfo) {
                const shareDetail = document.createElement("div");
                shareDetail.className = "maps__info--share-detail";
                shareDetail.style.marginTop = "8px";
                shareDetail.style.padding = "8px";
                shareDetail.style.backgroundColor = "#f0fdf4";
                shareDetail.style.borderRadius = "6px";
                shareDetail.style.wordBreak = "break-word";
                shareDetail.style.overflowWrap = "anywhere";

                const shareItem = document.createElement("div");
                const shareItemLabel = document.createElement("strong");
                shareItemLabel.textContent = "シェア中: ";
                shareItem.appendChild(shareItemLabel);
                shareItem.appendChild(document.createTextNode(shop.shareInfo.itemName));
                shareDetail.appendChild(shareItem);

                const shareDesc = document.createElement("div");
                const shareDescLabel = document.createElement("strong");
                shareDescLabel.textContent = "内容: ";
                shareDesc.appendChild(shareDescLabel);
                shareDesc.appendChild(document.createTextNode(shop.shareInfo.description));
                shareDetail.appendChild(shareDesc);

                const shareTakeDown = document.createElement("div");
                const shareTakeDownLabel = document.createElement("strong");
                shareTakeDownLabel.textContent = "取り下げ時間: ";
                shareTakeDown.appendChild(shareTakeDownLabel);
                shareTakeDown.appendChild(document.createTextNode(shop.shareInfo.takeDownTime));
                shareDetail.appendChild(shareTakeDown);

                shareDetailEl = shareDetail;
            }
        }

        // 独自クローズボタン
        const closeBtn = document.createElement("button");
        closeBtn.className = "maps__info--close";
        closeBtn.setAttribute("aria-label", "閉じる");
        closeBtn.title = "閉じる";
        closeBtn.textContent = "×";
        closeBtn.onclick = () => {
            try {
                if (this.infoWindow) this.infoWindow.close();
            } finally {
                triggerHideComments();
            }
        };

        headerRight.appendChild(badges);
        headerRight.appendChild(closeBtn);
        header.appendChild(headerRight);
        content.appendChild(header);
        if (shareDetailEl) content.appendChild(shareDetailEl);

        // フードシェアがある場合は content にフラグ用クラスを付与
        if (shop.foodshare) {
            content.classList.add("maps__info--has-foodshare");
        }

        // 住所エリア: アイコン + テキスト（短縮表示） + トグル
        const addressWrapper = document.createElement("div");
        addressWrapper.className = "maps__info--address-wrapper";

        const addrIcon = document.createElement("span");
        addrIcon.className = "maps__info--address-icon";
        addrIcon.textContent = "📍";
        addressWrapper.appendChild(addrIcon);

        const addressBtn = document.createElement("button");
        addressBtn.type = "button";
        addressBtn.className = "maps__info--address";
        const addressText = shop.address || "住所情報が登録されていません";
        addressBtn.textContent = `住所: ${addressText}`;
        // 住所テキストクリックで経路を開く
        addressBtn.onclick = () => {
            const lat = Number(shop.lat);
            const lng = Number(shop.lon);
            const hasCoords = Number.isFinite(lat) && Number.isFinite(lng);
            const q = encodeURIComponent(shop.name + (shop.address ? ' ' + shop.address : ''));
            const url = hasCoords
                ? `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}&travelmode=walking`
                : `https://www.google.com/maps/search/?api=1&query=${q}`;
            window.open(url, "_blank");
        };
        addressWrapper.appendChild(addressBtn);

        const toggleBtn = document.createElement("button");
        toggleBtn.type = "button";
        toggleBtn.className = "maps__info--address-toggle";
        toggleBtn.setAttribute("aria-expanded", "false");
        toggleBtn.title = "住所を展開";
        toggleBtn.textContent = "…";
        toggleBtn.onclick = () => {
            const expanded = toggleBtn.getAttribute("aria-expanded") === "true";
            if (expanded) {
                // 折りたたみ
                addressBtn.classList.remove("maps__info--address-expanded");
                toggleBtn.setAttribute("aria-expanded", "false");
                toggleBtn.title = "住所を展開";
                toggleBtn.textContent = "…";
            } else {
                // 展開
                addressBtn.classList.add("maps__info--address-expanded");
                toggleBtn.setAttribute("aria-expanded", "true");
                toggleBtn.title = "住所を折りたたむ";
                toggleBtn.textContent = "×";
            }
        };
        addressWrapper.appendChild(toggleBtn);

        content.appendChild(addressWrapper);

        // 営業時間エリア: アイコン + テキスト（短縮表示） + トグル
        const hoursWrapper = document.createElement("div");
        hoursWrapper.className = "maps__info--hours-wrapper";

        const hoursIcon = document.createElement("span");
        hoursIcon.className = "maps__info--hours-icon";
        hoursIcon.textContent = "🕒";
        hoursWrapper.appendChild(hoursIcon);

        const hoursBtn = document.createElement("button");
        hoursBtn.type = "button";
        hoursBtn.className = "maps__info--hours maps__info--hours-collapsed";
        const hoursText = shop.openTime || "営業時間情報が登録されていません";
        hoursBtn.textContent = `営業時間: ${hoursText}`;
        hoursWrapper.appendChild(hoursBtn);

        const hoursToggle = document.createElement("button");
        hoursToggle.type = "button";
        hoursToggle.className = "maps__info--hours-toggle";
        hoursToggle.setAttribute("aria-expanded", "false");
        hoursToggle.title = "営業時間を展開";
        hoursToggle.textContent = "…";
        hoursToggle.onclick = () => {
            const expanded = hoursToggle.getAttribute("aria-expanded") === "true";
            if (expanded) {
                hoursBtn.classList.remove("maps__info--hours-expanded");
                hoursBtn.classList.add("maps__info--hours-collapsed");
                hoursToggle.setAttribute("aria-expanded", "false");
                hoursToggle.title = "営業時間を展開";
                hoursToggle.textContent = "…";
            } else {
                hoursBtn.classList.add("maps__info--hours-expanded");
                hoursBtn.classList.remove("maps__info--hours-collapsed");
                hoursToggle.setAttribute("aria-expanded", "true");
                hoursToggle.title = "営業時間を折りたたむ";
                hoursToggle.textContent = "×";
            }
        };
        hoursWrapper.appendChild(hoursToggle);

        content.appendChild(hoursWrapper);

        // ボタン群は下部のstickyエリアに入れる
        const actions = document.createElement("div");
        actions.className = "maps__info__actions";
        const buttons = document.createElement("div");
        buttons.className = "maps__info--buttons";
        actions.appendChild(buttons);
        // actions は content の最後に追加（sticky が下端に張り付く）
        content.appendChild(actions);

        const reviewButton = document.createElement("button");
        reviewButton.textContent = "レビューする";

        // @ts-ignore Stimulus value accessors are defined at runtime
        const isCompany = this.hasIsCompanyValue ? this.isCompanyValue : false;

        if (isCompany) {
            // 企業アカウントの場合、ボタンを無効化
            reviewButton.classList.add("maps__info--button-disabled");
            reviewButton.disabled = true;
            // @ts-ignore Stimulus value accessors are defined at runtime
            const message = this.hasCompanyRestrictionMessageValue
                // @ts-ignore
                ? this.companyRestrictionMessageValue
                : "";
            reviewButton.title = message;
        } else {
            // 個人アカウントの場合、通常通り動作
            reviewButton.onclick = () => {
                window.location.href = `/reviews/new?reviewee_id=${shop.id}`;
            };
        }
        buttons.appendChild(reviewButton);

        // 住所クリックで経路を開くようにする（ヘッダー経路ボタンは廃止）

        const commentButton = document.createElement("button");
        commentButton.textContent = "コメントを見る";
        commentButton.onclick = () => {
            triggerShowComments(shop.id, shop.name);
        };
        buttons.appendChild(commentButton);

        // 情報ウィンドウを開く
        this.infoWindow.setContent(content);
        this.infoWindow.open(await this.map, marker);

        // Google Maps が生成する role="dialog" のラッパー要素に
        // フードシェア時のみクラスを付与して親要素にスタイルを適用する。
        // InfoWindow の DOM 挿入は非同期なので、軽く遅延させてから検索する。
        if (shop.foodshare) {
            setTimeout(() => {
                try {
                    const dialogs = document.querySelectorAll('[role="dialog"]');
                    for (const dialog of dialogs) {
                        if (dialog.contains(content)) {
                            dialog.classList.add('maps__dialog--has-foodshare');
                            break;
                        }
                    }
                } catch (e) {
                    // noop
                    console.warn('could not add dialog class for foodshare', e);
                }
            }, 50);
        }
    }

    /**
     * コントローラーが切断されたときのクリーンアップ
     */
    disconnect() {
        // 保留中のマーカー作成タイムアウトをクリア
        for (const timeoutId of this.pendingMarkerTimeouts.values()) {
            clearTimeout(timeoutId);
        }
        this.pendingMarkerTimeouts.clear();

        // すべてのマーカーをアニメーション付きで削除
        for (const [storeId, marker] of this.markers.entries()) {
            this.removeMarkerWithAnimation(storeId, marker);
        }

        // タイムアウトをクリア
        if (this.updateMarkersTimeout) {
            clearTimeout(this.updateMarkersTimeout);
        }
    }
}
