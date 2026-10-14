extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var preferences := root.get_node("Preferences")
	var saved_hats: Array = preferences.hats.duplicate()
	preferences.hats.assign([0, 3])
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.fighters[1].use_ai = false
	var left: Sprite2D = arena.get_node("Scenery/Clouds/CloudLeft")
	var right: Sprite2D = arena.get_node("Scenery/Clouds/CloudRight")
	left.set_physics_process(false)
	right.set_physics_process(false)
	var original_left := left.position.x
	var original_right := right.position.x
	left._physics_process(1.0)
	right._physics_process(1.0)
	check(left.position.x > original_left and right.position.x < original_right, "Clouds drift in opposite directions")
	left.position.x = 2000
	left._physics_process(1.0 / 60)
	check(left.position.x < 0, "Cloud wraps after leaving screen")
	for tick in range(180):
		arena._physics_process(1.0 / 60)
	var attacker: Fighter = arena.fighters[0]
	var victim: Fighter = arena.fighters[1]
	attacker.reset_fighter(400)
	victim.reset_fighter(480)
	victim.health = 8
	attacker.start_attack()
	for tick in range(5):
		arena._physics_process(1.0 / 60)
	check(victim.health == 0 and arena.cinematic_active, "Actual final strike begins cinematic")
	check(arena.match_audio.knockout.playing and arena.match_audio.last_event == "knockout", "Losing-player hurt cue starts with final blow")
	check(not arena.match_overlay.get_node("Victory").visible, "Game over waits for cinematic")
	check(arena.flying_hats.size() == 1 and not victim.visuals.body.get_node("Hat").visible, "Equipped helmet detaches")
	var start_position: Vector2 = arena.flying_hats[0].sprite.position
	var victim_start := victim.position
	var time_remaining: int = arena.round_ticks_remaining
	for tick in range(30):
		arena._physics_process(1.0 / 60)
	check(arena.flying_hats[0].sprite.position.y < start_position.y, "Helmet is hurled upward")
	check(victim.position.x > victim_start.x, "Slow cinematic continues final-hit knockback")
	check(arena.round_ticks_remaining == time_remaining, "Cinematic freezes match clock")
	check(arena.cinematic_active, "Slow motion persists before result")
	for tick in range(55):
		arena._physics_process(1.0 / 60)
	check(arena.match_over and arena.match_overlay.get_node("Victory").visible, "Result appears after cinematic")
	arena.restart()
	check(not arena.cinematic_active and arena.flying_hats.is_empty(), "Restart clears flying props")
	check(not arena.match_audio.knockout.playing, "Restart stops knockout hurt cue")
	check(victim.visuals.body.get_node("Hat").visible, "Restart restores equipped headgear")
	arena.match_audio.reset_match()
	await create_timer(0.15).timeout
	arena.free()
	await create_timer(0.15).timeout
	preferences.hats.assign(saved_hats)
	print("Cinematic checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
