extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.fighters[1].use_ai = false
	check(arena.round_ticks_remaining == 3600, "Match starts with exactly 60 seconds")
	var initial_position: Vector2 = arena.fighters[0].position
	for tick in range(60):
		arena._physics_process(1.0 / 60)
	check(arena.match_overlay.get_node("Countdown").text == "2", "Countdown advances to two")
	for tick in range(60):
		arena._physics_process(1.0 / 60)
	check(arena.match_overlay.get_node("Countdown").text == "1", "Countdown advances to one")
	for tick in range(59):
		arena._physics_process(1.0 / 60)
	check(not arena.fighters[0].enabled and arena.round_ticks_remaining == 3600, "Countdown freezes controls and match timer")
	check(arena.fighters[0].position == initial_position, "Countdown does not move fighters")
	check(arena.match_overlay.get_node("Countdown").modulate.a < 0.1, "Countdown text fades")
	arena._physics_process(1.0 / 60)
	check(arena.fighters[0].enabled and arena.match_overlay.get_node("Countdown").text == "FIGHT!", "Fight begins at exactly three seconds")
	for tick in range(3599):
		arena._physics_process(1.0 / 60)
	check(not arena.round_over and arena.round_ticks_remaining == 1, "Match stays live until last tick")
	check(not arena.match_overlay.get_node("Countdown").visible, "Fight text fades away during combat")
	arena.fighters[0].health = 80
	arena.fighters[1].health = 50
	arena._physics_process(1.0 / 60)
	check(arena.match_over and arena.round_ticks_remaining == 0, "Timeout ends match")
	check(arena.match_overlay.get_node("Victory").visible, "Result screen is visible")
	check(arena.match_overlay.get_node("Victory/Result").text == "TIME UP", "Result omits remaining-health numbers")
	check(arena.match_overlay.get_node("Victory/Title").text == "PLAYER 1 WINS!", "Timeout awards player with greater health")
	var position: Vector2 = arena.fighters[0].position
	arena._physics_process(1.0 / 60)
	check(arena.fighters[0].position == position, "Result screen freezes combat")
	arena.match_overlay.get_node("Victory/Rematch").pressed.emit()
	check(not arena.match_over and arena.round_ticks_remaining == 3600, "Play Again resets timer and match")
	check(not arena.match_overlay.get_node("Victory").visible, "Rematch hides result screen")
	for tick in range(180):
		arena._physics_process(1.0 / 60)
	arena.round_ticks_remaining = 1
	arena._physics_process(1.0 / 60)
	check(arena.match_overlay.get_node("Victory/Title").text == "DRAW!", "Equal health timeout is a draw")
	arena.restart()
	for tick in range(180):
		arena._physics_process(1.0 / 60)
	arena.fighters[0].health = 0
	arena._physics_process(1.0 / 60)
	check(arena.cinematic_active and not arena.match_overlay.get_node("Victory").visible, "KO delays result for cinematic")
	for tick in range(85):
		arena._physics_process(1.0 / 60)
	check(arena.match_overlay.get_node("Victory/Title").text == "PLAYER 2 WINS!", "Knockout ends single match immediately")
	check(not arena.fighters[0].enabled and not arena.fighters[1].enabled, "Both fighters disabled after match")
	arena.match_audio.reset_match()
	await create_timer(0.15).timeout
	arena.free()
	await create_timer(0.15).timeout # Let the audio mixer release stopped playback.
	print("Match checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
