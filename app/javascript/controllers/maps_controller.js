import { Controller } from "@hotwired/stimulus";
import { Loader } from "@googlemaps/js-api-loader";

// cSpell:ignore AIzaSyDPhWyiZRwXXlWX79iijYqNHUipdapFuNk
const loader = new Loader({
    apiKey: "",
    version: "weekly",
});

// 香川県範囲 34.2128846,134.065572,10.75z

const mapOptions = {
    mapId: "DEMO_MAP_ID",
    center: {
        lat: 34.2128846,
        lng: 134.065572,
    },
    zoom: 10.75,
};

// Connects to data-controller="maps"
/** @extends {Controller<HTMLDivElement>} */
export default class extends Controller {
    connect() {
        console.log("Maps controller connected");
        loader
            .importLibrary("maps")
            .then(({ Map }) => {
                console.log(new Map(this.element, mapOptions));
            })
            .catch((e) => {
                console.error(e);
            });
    }
}
