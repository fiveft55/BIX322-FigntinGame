extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := load("res://scenes/arena.tscn") as PackedScene
	var arena := scene.instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	for tick in range(180):
		arena._physics_process(1.0 / 60)
	for frame in range(360):
		arena._physics_process(1.0 / 60)
	if arena.fighters[0].health >= 100:
		push_error("AI did not reach and damage the player")
		quit(1)
		return
	arena.fighters[0].health = 0
	arena._physics_process(1.0 / 60)
	if not arena.round_over or arena.fighters[1].enabled:
		push_error("KO did not end round")
		quit(1)
		return
	arena.restart()
	if arena.round_over or arena.fighters[0].health != 100 or arena.countdown_ticks != 180:
		push_error("Restart did not restore round")
		quit(1)
		return
	arena.match_audio.reset_match()
	await create_timer(0.15).timeout
	arena.free()
	await create_timer(0.15).timeout # Let the audio mixer release stopped playback.
	print("Arena checks: PASS (AI damage, KO, restart)")
	quit(0)
