import "@types/web-bluetooth";
import "@types/google.maps";
import type { Application } from "@hotwired/stimulus";

declare global {
    interface Window {
        Stimulus: Application;
    }
}

export {};
