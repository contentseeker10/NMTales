extends Node

signal dialogue_action_triggered(npc: NPC, action: Dictionary)

signal npc_talked(npc_id: String)
signal location_entered(location_name: String)
signal menu_opened(menu_name: String)
signal quiz_completed(quiz_id: String)
signal mob_killed(mob_id: String)
