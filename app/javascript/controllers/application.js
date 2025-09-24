import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = true;

// 型を global.ts で定義済み
window.Stimulus = application;

export { application };
