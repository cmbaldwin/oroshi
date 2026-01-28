// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application";
import { UltimateTurboModalController } from "ultimate_turbo_modal";
import Dialog from "@stimulus-components/dialog";
import Notification from "@stimulus-components/notification";

// Register ultimate_turbo_modal controller
application.register("modal", UltimateTurboModalController);

// Register stimulus-components controllers
application.register("dialog", Dialog);
application.register("notification", Notification);

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);
