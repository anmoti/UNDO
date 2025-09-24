import type { Application } from "@hotwired/stimulus";
import "@types/google.maps";

declare global {
    interface Window {
        Stimulus: Application;
    }
}

export {};
