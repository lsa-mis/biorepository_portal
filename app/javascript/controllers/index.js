// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import PreparationController from "./preparation_controller"
import CollectionDropdownController from "./collection_dropdown_controller"

application.register("collection-dropdown", CollectionDropdownController)
application.register("preparation", PreparationController)
eagerLoadControllersFrom("controllers", application)
