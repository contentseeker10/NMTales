extends Node

@warning_ignore("unused_signal") signal dialogue_action_triggered(npc: NPC, action: Dictionary)

@warning_ignore("unused_signal") signal npc_talked(npc_id: String)
@warning_ignore("unused_signal") signal location_entered(location_name: String)
@warning_ignore("unused_signal") signal menu_opened(menu_name: String)
@warning_ignore("unused_signal") signal quiz_completed(quiz_id: String)
@warning_ignore("unused_signal") signal mob_killed(mob_id: String)

@warning_ignore("unused_signal") signal player_died()

@warning_ignore("unused_signal") signal page_title_changed(index: int, new_title: String)
