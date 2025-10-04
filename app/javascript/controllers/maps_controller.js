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

const loader = new Loader({
    apiKey: getGoogleMapsApiKey(),
    version: "weekly",
    libraries: ["maps", "marker"],
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

/**
 * @typedef {Object} Shop
 * @property {string} name
 * @property {number} lat
 * @property {number} lon
 * @property {string} openTime
 * @property {string} address
 * @property {boolean} [eco]
 * @property {boolean} [foodshare]
 */

/** @type {Shop[]} */
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
        eco: true,
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
    {
        name: "ふたばうどん",
        lat: 35.468838,
        lon: 133.066622,
        openTime: "24時間営業(例)",
        address: "島根県松江市学園南１丁目２−１",
        eco: true,
        foodshare: true,
    },
];

// Connects to data-controller="maps"
/** @extends {Controller<HTMLDivElement>} */
export default class MapsController extends Controller {
    /** @type {Promise<google.maps.Map>} */
    map;

    static targets = ["icon"];
    static values = {
        ecoIconUrl: String,
        foodshareIconUrl: String,
        activeUrl: String,
        inactiveUrl: String,
    };

    /**
     * @param  {Context} context
     */
    constructor(context) {
        super(context);

        this.map = loader.importLibrary("maps").then(async ({ Map: GMaps }) => {
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
        // 各店舗にマーカーを作成
        for (const shop of shops) {
            const { AdvancedMarkerElement } = await loader.importLibrary(
                "marker"
            );
            const position = { lat: shop.lat, lng: shop.lon };

            // カスタムマーカーアイコンを作成
            const markerIcon = document.createElement("div");
            markerIcon.className = "maps__marker";

            // マーカーを作成
            const marker = new AdvancedMarkerElement({
                position: position,
                map: await this.map,
                title: shop.name,
                content: markerIcon,
                gmpClickable: true,
            });

            marker.addListener("click", () => {
                // マーカーがクリックされたときに情報ウィンドウを表示
                this.showShopInfo(shop, marker);
            });
        }
    }

    /**
     * @param {Shop} shop
     * @param {google.maps.marker.AdvancedMarkerElement} marker
     */
    async showShopInfo(shop, marker) {
        const { InfoWindow } = await loader.importLibrary("maps");

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
            // @ts-ignore
            ecoImg.src = this.ecoIconUrlValue;
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
            //@ts-ignore
            foodshareImg.src = this.foodshareIconUrlValue;
            foodshareOptions.appendChild(foodshareImg);

            const foodshareDesc = document.createElement("span");
            foodshareDesc.className = "maps__info--foodshare";
            foodshareDesc.textContent = "フードシェア実施中";
            foodshareOptions.appendChild(foodshareDesc);
            content.appendChild(foodshareOptions);
        }

        const address = document.createElement("div");
        address.textContent = `住所: ${shop.address}`;
        content.appendChild(address);

        const openTime = document.createElement("div");
        openTime.textContent = `営業時間: ${shop.openTime}`;
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
