// Controllers are listed one by one. velvetkit:add appends the kit's own.
import { application } from "./application"

import AutosubmitController from "./autosubmit_controller"
application.register("autosubmit", AutosubmitController)

import ClipboardController from "./clipboard_controller"
application.register("clipboard", ClipboardController)

import FilterController from "./filter_controller"
application.register("filter", FilterController)

import SearchController from "./search_controller"
application.register("search", SearchController)

import SidebarScrollController from "./sidebar_scroll_controller"
application.register("sidebar-scroll", SidebarScrollController)

import ThemePlaygroundController from "./theme_playground_controller"
application.register("theme-playground", ThemePlaygroundController)

import UI__AccordionController from "./ui/accordion_controller"
application.register("ui--accordion", UI__AccordionController)

import UI__AlertController from "./ui/alert_controller"
application.register("ui--alert", UI__AlertController)

import UI__BannerController from "./ui/banner_controller"
application.register("ui--banner", UI__BannerController)

import UI__PopoverController from "./ui/popover_controller"
application.register("ui--popover", UI__PopoverController)

import UI__DataGridController from "./ui/data_grid_controller"
application.register("ui--data-grid", UI__DataGridController)

import UI__DatePickerController from "./ui/date_picker_controller"
application.register("ui--date-picker", UI__DatePickerController)

import UI__DialogController from "./ui/dialog_controller"
application.register("ui--dialog", UI__DialogController)

import UI__MenuController from "./ui/menu_controller"
application.register("ui--menu", UI__MenuController)

import UI__PasswordVisibilityController from "./ui/password_visibility_controller"
application.register("ui--password-visibility", UI__PasswordVisibilityController)

import UI__SidebarController from "./ui/sidebar_controller"
application.register("ui--sidebar", UI__SidebarController)

import UI__TabsController from "./ui/tabs_controller"
application.register("ui--tabs", UI__TabsController)

import UI__ThemeController from "./ui/theme_controller"
application.register("ui--theme", UI__ThemeController)

import UI__TooltipController from "./ui/tooltip_controller"
application.register("ui--tooltip", UI__TooltipController)

import UI__SelectController from "./ui/select_controller"
application.register("ui--select", UI__SelectController)
