// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import PreparationController from "./preparation_controller"
import CollectionDropdownController from "./collection_dropdown_controller"
import EditOptionsController from "./edit_options_controller"
import ShowOptionsController from "./show_options_controller"
import CheckboxGroupRequiredController from "./checkbox_group_required_controller"
import AutosubmitController from "./autosubmit_controller"
import RemoteModalController from "./remote_modal_controller"

application.register("collection-dropdown", CollectionDropdownController)
application.register("preparation", PreparationController)
application.register("edit-options", EditOptionsController)
application.register("show-options", ShowOptionsController)
application.register("checkbox-group-required", CheckboxGroupRequiredController)
application.register("autosubmit", AutosubmitController)
application.register("remote-modal", RemoteModalController)
eagerLoadControllersFrom("controllers", application)
