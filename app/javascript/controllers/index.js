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
import ModalResetController from "./modal_reset_controller"
import NavbarController from "./navbar_controller"
import SkiplinkController from "./skiplink_controller"

application.register("collection-dropdown", CollectionDropdownController)
application.register("preparation", PreparationController)
application.register("edit-options", EditOptionsController)
application.register("show-options", ShowOptionsController)
application.register("checkbox-group-required", CheckboxGroupRequiredController)
application.register("autosubmit", AutosubmitController)
application.register("remote-modal", RemoteModalController)
application.register("modal-reset", ModalResetController)
application.register("navbar", NavbarController)
application.register("skiplink", SkiplinkController)
eagerLoadControllersFrom("controllers", application)
