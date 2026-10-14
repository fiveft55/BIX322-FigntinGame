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
	var saved := [preferences.difficulty, preferences.music_volume, preferences.effects_volume,
		preferences.voice_volume, preferences.characters.duplicate(), preferences.weapons.duplicate()]
	preferences.settings_path = "user://menu-test-settings.cfg"
	var menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	check(menu.music.playing and menu.music.stream.loop, "Menu music starts and loops")
	menu.get_node("Home/SettingsButton").pressed.emit()
	check(menu.options.visible and not menu.home.visible, "Settings button opens settings page")
	menu.get_node("Settings/MusicSlider").value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music slider can mute music")
	menu.get_node("Settings/EffectsSlider").value = 50
	check(is_equal_approx(preferences.effects_volume, 0.5), "Effects volume changes independently")
	menu.set_difficulty(2)
	menu.choose_character(0, 2)
	menu.choose_character(1, 7)
	menu.choose_weapon(0, 1)
	menu.choose_weapon(1, 3)
	preferences.difficulty = 0
	preferences.characters.assign([0, 5])
	preferences.weapons.assign([0, 0])
	preferences.load_settings()
	check(preferences.difficulty == 2 and preferences.characters == [2, 7], "Difficulty and characters persist")
	check(preferences.weapons == [1, 3] and preferences.music_volume == 0, "Weapons and audio volumes persist")
	menu.show_page(menu.controls)
	check(menu.get_node("Controls/Info").text.contains("Hold shield"), "Controls page explains combat keys")
	menu.start_game(true)
	await create_timer(0.65).timeout
	var arena := current_scene
	arena.set_physics_process(false)
	check(not arena.fighters[1].use_ai, "Local mode starts without AI")
	check(arena.fighters[0].visuals.body.texture.resource_path.ends_with("character_roundRed.png"), "Chosen player one character reaches fight")
	check(arena.fighters[1].visuals.sword.texture.resource_path.ends_with("item_pencil.png"), "Chosen player two weapon reaches fight")
	check(arena.bars[0].get_theme_stylebox("fill").bg_color == GameSettings.CHARACTERS[2].color, "Health bar matches character color")
	arena.return_to_menu()
	await create_timer(0.2).timeout
	menu = current_scene
	check(menu.has_node("Characters"), "Result return opens main menu")
	menu.start_game(false)
	await create_timer(0.65).timeout
	arena = current_scene
	arena.set_physics_process(false)
	check(arena.fighters[1].use_ai, "AI mode starts with opponent AI")
	arena.match_audio.reset_match()
	await create_timer(0.15).timeout
	arena.free()
	current_scene = null
	await create_timer(0.15).timeout
	# Compare real fighter decisions under different AI profiles.
	var fighter := Fighter.new()
	var opponent := Fighter.new()
	root.add_child(fighter)
	root.add_child(opponent)
	fighter.opponent = opponent
	opponent.opponent = fighter
	fighter.use_ai = true
	for action in ["p1_left", "p1_right", "p1_block"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	preferences.difficulty = 0
	fighter.reset_fighter(400)
	opponent.reset_fighter(700)
	fighter.tick(1.0 / 60)
	var easy_speed := fighter.velocity.x
	preferences.difficulty = 2
	fighter.reset_fighter(400)
	fighter.tick(1.0 / 60)
	check(fighter.velocity.x > easy_speed, "Hard AI moves faster than Easy")
	opponent.reset_fighter(480)
	preferences.difficulty = 0
	fighter.reset_fighter(400)
	for tick in range(16):
		fighter.tick(1.0 / 60)
	check(fighter.state == Fighter.State.IDLE, "Easy AI waits before attacking")
	preferences.difficulty = 2
	fighter.reset_fighter(400)
	for tick in range(16):
		fighter.tick(1.0 / 60)
	check(fighter.state == Fighter.State.ATTACKING, "Hard AI attacks sooner")
	fighter.free()
	opponent.free()
	preferences.difficulty = saved[0]
	preferences.music_volume = saved[1]
	preferences.effects_volume = saved[2]
	preferences.voice_volume = saved[3]
	preferences.characters.assign(saved[4])
	preferences.weapons.assign(saved[5])
	preferences.local_mode = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(preferences.settings_path))
	preferences.settings_path = preferences.SAVE_PATH
	preferences.apply_volumes()
	print("Menu checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
