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
	var audio: MatchAudio = arena.match_audio
	check(audio.voice.stream == audio.countdown_three, "Three is announced at match start")
	check(not audio.music.playing, "Music waits for the fight")
	for tick in range(60):
		arena._physics_process(1.0 / 60)
	check(audio.voice.stream == audio.countdown_two, "Two follows countdown timing")
	for tick in range(60):
		arena._physics_process(1.0 / 60)
	check(audio.voice.stream == audio.countdown_one, "One follows countdown timing")
	for tick in range(60):
		arena._physics_process(1.0 / 60)
	check(audio.music.playing and audio.music.stream.loop, "Battle music starts with looping enabled")
	check(audio.voice.stream == audio.fight_voice, "Fight voice matches fight text")
	for bus in ["Music", "Voice", "SFX"]:
		check(AudioServer.get_bus_index(bus) >= 0, "Separate volume bus exists: " + bus)
	var fighter: Fighter = arena.fighters[0]
	fighter.start_attack()
	for tick in range(ceili(Fighter.ATTACKS[0].startup / GameSettings.ATTACK_SPEED)):
		fighter.tick(1.0 / 60)
	check(audio.last_event == "sword", "Active sword frame emits effect")
	fighter.reset_fighter(400)
	fighter.buffer.push(&"jump")
	fighter.tick(1.0 / 60)
	check(audio.last_event == "jump", "Jump emits effect")
	fighter.receive_hit(Fighter.ATTACKS[0], arena.fighters[1])
	check(audio.last_event == "hit", "Damage emits hit effect")
	fighter.reset_fighter(400)
	fighter.facing = 1
	fighter.change_state(Fighter.State.BLOCKING)
	fighter.receive_hit(Fighter.ATTACKS[0], arena.fighters[1])
	check(audio.last_event == "block", "Front guard emits block effect")
	arena.fighters[1].health = 0
	arena.finish_round()
	check(not audio.music.playing, "Music stops at result screen")
	check(audio.voice.stream == audio.player_one_voice, "Correct winner announced first")
	audio.play_next_voice()
	check(audio.voice.stream == audio.winner_voice, "Winner announcement follows player name")
	arena.restart()
	check(audio.voice_queue.is_empty() and not audio.music.playing, "Rematch clears old audio")
	arena.match_audio.reset_match()
	await create_timer(0.15).timeout
	arena.free()
	await create_timer(0.15).timeout
	print("Audio checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
