// Import and register all your controllers
import { application } from "./application";

import HamburgerController from "./hamburger_controller";
application.register("hamburger", HamburgerController);

import ModalController from "./modal_controller";
application.register("modal", ModalController);

import ClipboardController from "./clipboard_controller";
application.register("clipboard", ClipboardController);

import FlashController from "./flash_controller";
application.register("flash", FlashController);

import AutocompleteController from "./autocomplete_controller";
application.register("autocomplete", AutocompleteController);

import CardEditController from "./card_edit_controller";
application.register("card-edit", CardEditController);

import MemoEditController from "./memo_edit_controller";
application.register("memo-edit", MemoEditController);

import MemberDeleteController from "./member_delete_controller";
application.register("member-delete", MemberDeleteController);
