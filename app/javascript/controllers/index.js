import { application } from "controllers/application";
// @ts-ignore
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

// Import and register all your controllers from the importmap via controllers/**/*_controller
eagerLoadControllersFrom("controllers", application);
