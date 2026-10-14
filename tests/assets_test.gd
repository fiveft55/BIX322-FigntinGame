extends SceneTree
## Fail on missing imported textures or mismatched character configuration.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	for fighter in arena.fighters:
		var visual: FighterVisual = fighter.visuals
		var authored_position := visual.front_hand.position
		fighter.state = Fighter.State.IDLE
		visual.update_pose()
		if visual.front_hand.position != authored_position:
			push_error("Idle pose did not preserve scene-authored hand placement")
			quit(1)
			return
		fighter.start_attack()
		for frame in range(Fighter.ATTACKS[0].startup):
			fighter.tick(1.0 / 60)
		if not visual.effect.visible or visual.sword_grip.rotation != visual.base_sword_rotation:
			push_error("Active sword pose did not follow combat timing")
			quit(1)
			return
		for texture in [visual.body.texture, visual.front_hand.texture, visual.shield.texture, visual.effect.texture, visual.sword.texture]:
			if texture == null or texture.get_width() == 0:
				push_error("Fighter texture failed to load")
				quit(1)
				return
	for sprite in arena.get_node("Scenery").find_children("*", "Sprite2D", true, false):
		if sprite.texture == null:
			push_error("Scenery texture failed to load")
			quit(1)
			return
	print("Asset checks: PASS (both fighters, guard, effects, scenery)")
	quit(0)
