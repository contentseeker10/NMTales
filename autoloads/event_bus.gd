## A global event bus autoload that facilitates decoupled communication between systems.
##
## Acts as a central hub for publishing and subscribing to game events without
## direct dependencies between the source and listener objects.
extends Node

## Emitted when an action is triggered during a dialogue sequence.
## [param npc] The NPC node initiating or associated with the dialogue.
## [param action] A dictionary containing the action details and parameters.
@warning_ignore("unused_signal") signal dialogue_action_triggered(npc: NPC, action: Dictionary)

## Emitted when the player finishes talking or interacts with an NPC.
## [param npc_id] The unique identifier of the NPC.
@warning_ignore("unused_signal") signal npc_talked(npc_id: String)

## Emitted when the player enters a new location or zone.
## [param location_name] The name or identifier of the entered location.
@warning_ignore("unused_signal") signal location_entered(location_name: String)

## Emitted when a user interface menu is opened.
## [param menu_name] The name or identifier of the opened menu.
@warning_ignore("unused_signal") signal menu_opened(menu_name: String)

## Emitted when a quiz or questionnaire is successfully completed.
## [param quiz_id] The unique identifier of the completed quiz.
@warning_ignore("unused_signal") signal quiz_completed(quiz_id: String)

## Emitted when a mob/enemy is defeated.
## [param mob_id] The unique identifier of the killed mob.
@warning_ignore("unused_signal") signal mob_killed(mob_id: String)

## Emitted when the player character dies.
@warning_ignore("unused_signal") signal player_died()

## Emitted when the title of a page (e.g., in a book or UI) is changed.
## [param index] The index of the page that changed.
## [param new_title] The new title string for the page.
@warning_ignore("unused_signal") signal page_title_changed(index: int, new_title: String)

