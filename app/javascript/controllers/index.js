// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import PreparationController from "./preparation_controller"

application.register("preparation", PreparationController)
eagerLoadControllersFrom("controllers", application)
