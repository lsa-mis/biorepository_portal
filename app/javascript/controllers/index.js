// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import PreparationController from "./preparation_controller"
import CollectionDropdownController from "./collection_dropdown_controller"
import EditOptionsController from "./edit_options_controller"

application.register("collection-dropdown", CollectionDropdownController)
application.register("preparation", PreparationController)
application.register("edit-options", EditOptionsController)
eagerLoadControllersFrom("controllers", application)
