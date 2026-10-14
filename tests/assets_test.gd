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
		fighter.change_state(Fighter.State.BLOCKING)
		fighter.state_frame = visual.guard_raise_frames
		visual.update_pose()
		var raised_position := visual.rear_hand.position
		if visual.shield.get_parent() != visual.rear_hand or not visual.shield.visible:
			push_error("Shield must stay attached to the free hand")
			quit(1)
			return
		if raised_position != visual.base_positions[visual.rear_hand] + visual.guard_hand_offset:
			push_error("Guard did not raise the shield hand")
			quit(1)
			return
		fighter.facing = 1 if fighter.opponent.position.x > fighter.position.x else -1
		fighter.receive_hit(Fighter.ATTACKS[0], fighter.opponent)
		if not fighter.guard_hit or visual.rear_hand.position != raised_position + visual.guard_recoil_offset:
			push_error("Blocked attack did not recoil the raised shield hand")
			quit(1)
			return
		fighter.change_state(Fighter.State.IDLE)
		visual.update_pose()
		if visual.rear_hand.position != visual.base_positions[visual.rear_hand] or fighter.guard_hit:
			push_error("Idle did not restore shield hand and clear guard reaction")
			quit(1)
			return
	for sprite in arena.get_node("Scenery").find_children("*", "Sprite2D", true, false):
		if sprite.texture == null:
			push_error("Scenery texture failed to load")
			quit(1)
			return
	print("Asset checks: PASS (both fighters, guard, effects, scenery)")
	quit(0)
