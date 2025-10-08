import { Controller } from "@hotwired/stimulus";
import { Loader } from "@googlemaps/js-api-loader";
import { triggerShowComments } from "controllers/comments_controller";

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
 * @typedef {Object} StoreFeature
 * @property {number} id
 * @property {string} name
 * @property {number} lat
 * @property {number} lon
 * @property {string | null | undefined} [openTime]
 * @property {string | null | undefined} [address]
 * @property {boolean | null | undefined} [eco]
 * @property {boolean | null | undefined} [foodshare]
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

    static targets = ["icon"];
    static values = {
        ecoIconUrl: String,
        foodshareIconUrl: String,
        stores: Array,
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

        // マーカーを作成して店舗を表示
        await this.createShopMarkers();
    }

    async createShopMarkers() {
        // @ts-ignore Stimulus value accessors are defined at runtime
        const stores = this.hasStoresValue ? this.storesValue : [];

        if (!stores.length) {
            console.info("No store data provided for map markers.");
            return;
        }

        const { AdvancedMarkerElement } = await this.loader.importLibrary(
            "marker",
        );
        const map = await this.map;

        for (const store of stores) {
            const lat = Number(store.lat);
            const lon = Number(store.lon ?? store.lng ?? store.longitude);

            if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
                console.warn("Skipping store without valid coordinates", store);
                continue;
            }

            const position = { lat, lng: lon };

            // カスタムマーカーアイコンを作成
            const markerIcon = document.createElement("div");
            markerIcon.className = "maps__marker";

            // マーカーを作成
            const marker = new AdvancedMarkerElement({
                position,
                map,
                title: store.name,
                content: markerIcon,
                gmpClickable: true,
            });

            marker.addListener("click", () => {
                // マーカーがクリックされたときに情報ウィンドウを表示
                this.showShopInfo(store, marker);
            });
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

        // 情報ウィンドウのコンテンツを作成
        const content = document.createElement("div");
        content.className = "maps__info";

        const title = document.createElement("h3");
        title.className = "maps__info--title";
        title.textContent = shop.name;
        content.appendChild(title);

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
            ecoDesc.className = "maps__info--eco";
            ecoDesc.textContent = "環境に優しいうどん店";
            EcoOptions.appendChild(ecoDesc);
            content.appendChild(EcoOptions);
        }
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
            foodshareDesc.className = "maps__info--foodshare";
            foodshareDesc.textContent = "フードシェア実施中";
            foodshareOptions.appendChild(foodshareDesc);
            content.appendChild(foodshareOptions);
        }

        const address = document.createElement("div");
        const addressText = shop.address || "住所情報が登録されていません";
        address.textContent = `住所: ${addressText}`;
        content.appendChild(address);

        const openTime = document.createElement("div");
        const openTimeText = shop.openTime || "営業時間情報が登録されていません";
        openTime.textContent = `営業時間: ${openTimeText}`;
        content.appendChild(openTime);

        const buttons = document.createElement("div");
        buttons.className = "maps__info--buttons";
        content.appendChild(buttons);

        const reviewButton = document.createElement("button");
        reviewButton.textContent = "レビューする";
        reviewButton.onclick = () => void 0;
        buttons.appendChild(reviewButton);

        const commentButton = document.createElement("button");
        commentButton.textContent = "コメントを見る";
        commentButton.onclick = this.commentView.bind(this);
        buttons.appendChild(commentButton);

        // 情報ウィンドウを開く
        this.infoWindow.setContent(content);
        this.infoWindow.open(await this.map, marker);
    }

    /**
     * レビューフォームを表示する関数
     */
    commentView() {
        triggerShowComments();
    }
}
