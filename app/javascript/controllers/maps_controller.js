import { Controller } from "@hotwired/stimulus";
import { Loader } from "@googlemaps/js-api-loader";

// Helper to read Google Maps API key from meta tag
function getGoogleMapsApiKey() {
    /** @type {HTMLMetaElement} */
    const meta = document.querySelector('meta[name="google-maps-api-key"]');
    if (!meta) {
        console.warn("Google Maps API key meta tag not found.");
        return "";
    }
    return meta.content;
}

const loader = new Loader({
    apiKey: getGoogleMapsApiKey(),
    version: "weekly",
});

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

const shops = [
    {
        name: "味庄",
        lat: 34.3438,
        lon: 134.0461,
        openTime: "5:00～14:00 麺終了次第",
        address: "香川県高松市西の丸町5-15",
    },
    {
        name: "こだわり麺や高松店",
        lat: 34.3415,
        lon: 134.0498,
        openTime: "9:00〜20:00（土日祝6:30〜15:00）",
        address: "香川県高松市天神前5-25",
    },
    {
        name: "さか枝うどん本店",
        lat: 34.3397,
        lon: 134.0485,
        openTime: "7:00～15:00",
        address: "香川県高松市番町5-2-23",
    },
    {
        name: "めりけんや高松駅前店",
        lat: 34.3439,
        lon: 134.0465,
        openTime: "7:00〜20:00",
        address: "香川県高松市西の丸町6-20",
    },
    {
        name: "植田うどん",
        lat: 34.3412,
        lon: 134.0492,
        openTime: "9:38～14:30（麺終了次第）",
        address: "香川県高松市内町1-8",
    },
    {
        name: "うどん市場めんくい",
        lat: 34.3423,
        lon: 134.0478,
        openTime: "月～金曜 11:00～15:00, 土日祝 11:00～14:00, 麺終了次第",
        address: "香川県高松市塩屋町9-7",
    },
    {
        name: "釜揚げうどん 岡じま",
        lat: 34.3428,
        lon: 134.0482,
        openTime: "10:00～15:00",
        address: "香川県高松市寿町1-4-3 高松中央通りビル１Ｆ北側",
    },
    {
        name: "さか枝うどん 南新町店",
        lat: 34.3401,
        lon: 134.0489,
        openTime: "7:00～17:00",
        address: "香川県高松市南新町4-6",
    },
    {
        name: "松下製麺所",
        lat: 34.335057,
        lon: 134.044763,
        openTime: "7時～15時頃（麺がなくなり次第終了）",
        address: "香川県高松市中野町2-2",
    },
    {
        name: "手打うどん 三徳",
        lat: 34.292697,
        lon: 134.069001,
        openTime: "11時～16時（LO15時45分）",
        address: "香川県高松市林町390-1",
    },
    {
        name: "手打十段 うどんバカ一代",
        lat: 34.336594,
        lon: 134.058423,
        openTime: "6時～18時",
        address: "香川県高松市多賀町1-6-7",
    },
    {
        name: "さぬき一番 一宮店",
        lat: 34.287691,
        lon: 134.033044,
        openTime: "10時～21時",
        address: "香川県高松市三名町105-2",
    },
    {
        name: "本格手打ちもり家",
        lat: 34.239623,
        lon: 134.051456,
        openTime: "10:30～18:00",
        address: "香川県高松市香川町川内原1575-1",
    },
    {
        name: "本格手打ちうどん おか泉",
        lat: 34.309226,
        lon: 133.821004,
        openTime: "11:00（土日祝は10:45）～19:00",
        address: "香川県綾歌郡宇多津町浜八番丁129-10",
    },
    {
        name: "元祖セルフうどんの店 竹清",
        lat: 34.338077,
        lon: 134.042292,
        openTime: "11:00～14:30（売り切れ次第終了）",
        address: "香川県高松市亀岡町2-23",
    },
    {
        name: "めりけんや",
        lat: 34.313155,
        lon: 133.814618,
        openTime: "9:00～15:00（土日祝は16:00まで）",
        address: "香川県綾歌郡宇多津町浜三番丁36-1",
    },
];

// Connects to data-controller="maps"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    /** @type {google.maps.Map} */
    map;

    async connect() {
        console.log("Maps controller connected");
        const { Map: GMaps } = await loader.importLibrary("maps");
        this.map = new GMaps(this.element, mapOptions);
        console.log("Map initialized:", this.map);

        this.map.addListener("click", this.onMapClick.bind(this));

        // マーカーを作成して店舗を表示
        await this.createShopMarkers();
    }

    /** @param {google.maps.MapMouseEvent} event */
    async onMapClick(event) {}

    async createShopMarkers() {
        // 各店舗にマーカーを作成
        for (const shop of shops) {
            const { AdvancedMarkerElement } = await loader.importLibrary(
                "marker"
            );
            const position = { lat: shop.lat, lng: shop.lon };

            // カスタムマーカーアイコンを作成
            const markerIcon = document.createElement("div");
            markerIcon.className = "map__marker";

            // マーカーを作成
            const marker = new AdvancedMarkerElement({
                position: position,
                map: this.map,
                title: shop.name,
                content: markerIcon,
                gmpClickable: true,
            });

            // ホバーエフェクト用のスタイル
            const originalContent = markerIcon.innerHTML;

            // ホバーイベント
            marker.addListener("mouseover", () => {
                // ホバー時に名前を表示するツールチップ
                const tooltip = document.createElement("div");
                tooltip.className = "shop-tooltip";
                tooltip.textContent = shop.name;
                tooltip.style.cssText = `
                    position: absolute;
                    background: rgba(0, 0, 0, 0.8);
                    color: white;
                    padding: 4px 8px;
                    border-radius: 4px;
                    font-size: 12px;
                    white-space: nowrap;
                    z-index: 1000;
                    pointer-events: none;
                    transform: translate(-50%, -100%);
                    margin-top: -8px;
                `;

                markerIcon.appendChild(tooltip);
                markerIcon.style.transform = "scale(1.1)";
            });

            marker.addListener("mouseout", () => {
                // ツールチップを削除
                const tooltip = markerIcon.querySelector(".shop-tooltip");
                if (tooltip) {
                    tooltip.remove();
                }
                markerIcon.style.transform = "scale(1)";
            });

            // クリックイベント
            marker.addListener("click", () => {
                this.showShopInfo(shop, marker);
            });

            // マーカーを配列に保存
            if (!this.markers) {
                this.markers = [];
            }
            this.markers.push({ marker, shop });
        }
    }

    async showShopInfo(shop, marker) {
        const { InfoWindow } = await loader.importLibrary("maps");

        // 既存の情報ウィンドウがあれば閉じる
        if (this.infoWindow) {
            this.infoWindow.close();
        }

        // 新しい情報ウィンドウを作成
        this.infoWindow = new InfoWindow();

        // 情報ウィンドウのコンテンツを作成
        const content = `
            <div style="min-width: 200px; padding: 12px; font-family: Arial, sans-serif;">
                <h3 style="margin: 0 0 8px 0; color: #333; font-size: 16px;">${shop.name}</h3>
                <div style="margin-bottom: 6px; color: #666; font-size: 13px;">
                    <strong>住所:</strong> ${shop.address}
                </div>
                <div style="color: #666; font-size: 13px;">
                    <strong>営業時間:</strong> ${shop.openTime}
                </div>
            </div>
        `;

        // 情報ウィンドウを開く
        this.infoWindow.setContent(content);
        this.infoWindow.open(this.map, marker);
    }
}
