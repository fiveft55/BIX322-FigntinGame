extends Node2D
## Match coordinator: controls, fighter simulation, simultaneous hits, and HUD.

var fighters: Array[Fighter] = []
var bars: Array[ProgressBar] = []
var round_over := false
var match_over := false
var round_ticks_remaining := 0
var countdown_ticks := 0
var fight_fade_ticks := 0
var match_overlay: CanvasLayer
var match_audio: MatchAudio
var spawn_positions: Array[Vector2] = []

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	for action in GameSettings.KEYS:
		bind(action, GameSettings.KEYS[action])
	fighters.assign([$Fighters/Player1, $Fighters/Player2])
	fighters[1].use_ai = not Preferences.local_mode
	for fighter in fighters:
		spawn_positions.append(fighter.position)
	match_audio = (load("res://scenes/match_audio.tscn") as PackedScene).instantiate()
	add_child(match_audio)
	for fighter in fighters:
		fighter.combat_sound.connect(match_audio.on_combat_sound)
	fighters[0].opponent = fighters[1]
	fighters[1].opponent = fighters[0]
	create_hud()
	match_overlay = (load("res://scenes/match_overlay.tscn") as PackedScene).instantiate()
	add_child(match_overlay)
	match_overlay.get_node("Victory/Rematch").pressed.connect(restart)
	match_overlay.get_node("Victory/Quit").pressed.connect(func() -> void: get_tree().quit())
	match_overlay.get_node("Victory/MainMenu").pressed.connect(return_to_menu)
	restart()

func bind(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action) # Settings are the single source of key bindings.
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func create_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "SCRIBBLE FIGHTERS"
	title.position = Vector2(400, 20)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("28333b"))
	layer.add_child(title)
	for i in range(2):
		var bar := ProgressBar.new()
		bar.position = Vector2(45 if i == 0 else 727, 85)
		bar.size = Vector2(380, 26)
		bar.max_value = GameSettings.MAX_HEALTH
		var fill := StyleBoxFlat.new()
		fill.bg_color = GameSettings.CHARACTERS[Preferences.characters[i]].color
		fill.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("fill", fill)
		var background := StyleBoxFlat.new()
		background.bg_color = Color("e0ded7")
		background.border_color = Color("28333b")
		background.set_border_width_all(2)
		background.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("background", background)
		bar.show_percentage = false
		layer.add_child(bar)
		bars.append(bar)
	var control_labels: Array[String] = []
	for player in ["p1", "p2"]:
		control_labels.append("%s %s/%s move · %s jump · %s attack · %s guard" % [
			player.to_upper(),
			GameSettings.key_label(player + "_left"),
			GameSettings.key_label(player + "_right"),
			GameSettings.key_label(player + "_jump"),
			GameSettings.key_label(player + "_attack"),
			GameSettings.key_label(player + "_block"),
		])
	print(" | ".join(control_labels))
	print("%s AI/local · %s hitboxes · %s restart" % [
		GameSettings.key_label("ai"),
		GameSettings.key_label("boxes"),
		GameSettings.key_label("restart"),
	])
	print("Collision debug: green hurtboxes, red attack hitboxes. States log on transition.")

func restart() -> void:
	# R and Play Again restart the entire match, not just the current round.
	match_over = false
	match_overlay.get_node("Victory").hide()
	start_round()


func start_round() -> void:
	round_over = false
	round_ticks_remaining = GameSettings.ROUND_SECONDS * 60
	for i in range(fighters.size()):
		fighters[i].reset_fighter(spawn_positions[i].x)
		fighters[i].enabled = false
	match_audio.reset_match()
	match_audio.say(match_audio.countdown_three)
	countdown_ticks = 180
	fight_fade_ticks = 0
	var countdown: Label = match_overlay.get_node("Countdown")
	countdown.text = "3"
	countdown.modulate.a = 1.0
	countdown.show()
	update_match_hud()


func finish_round() -> void:
	if round_over:
		return # Resolve a match exactly once.
	round_over = true
	for fighter in fighters:
		fighter.enabled = false
		fighter.remove_hitbox()
	match_over = true
	match_overlay.get_node("Countdown").hide()
	var result := "DRAW!"
	if fighters[0].health != fighters[1].health:
		var winner := 1 if fighters[0].health > fighters[1].health else 2
		result = "PLAYER %d WINS!" % winner
	var winner_number := 0 if fighters[0].health == fighters[1].health else (1 if fighters[0].health > fighters[1].health else 2)
	match_audio.finish_match(winner_number, round_ticks_remaining == 0)
	match_overlay.get_node("Victory/Title").text = result
	var reason := "TIME UP" if round_ticks_remaining == 0 else "KNOCKOUT"
	match_overlay.get_node("Victory/Result").text = reason
	match_overlay.get_node("Victory").show()
	match_overlay.get_node("Victory/Rematch").grab_focus()
	update_match_hud()


func update_match_hud() -> void:
	var seconds := ceili(round_ticks_remaining / 60.0)
	match_overlay.get_node("Clock").text = "%02d:%02d" % [seconds / 60, seconds % 60]
	for i in range(fighters.size()):
		bars[i].value = fighters[i].health


func update_countdown() -> void:
	var label: Label = match_overlay.get_node("Countdown")
	countdown_ticks -= 1
	if countdown_ticks == 120:
		match_audio.say(match_audio.countdown_two)
	elif countdown_ticks == 60:
		match_audio.say(match_audio.countdown_one)
	if countdown_ticks > 0:
		label.text = str(ceili(countdown_ticks / 60.0))
		var elapsed_in_second := (180 - countdown_ticks) % 60
		label.modulate.a = 1.0 - elapsed_in_second / 60.0
	else:
		match_audio.begin_battle()
		label.text = "FIGHT!"
		label.modulate.a = 1.0
		fight_fade_ticks = 30
		for fighter in fighters:
			fighter.buffer.clear()
			fighter.enabled = true


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart()
	if Input.is_action_just_pressed("boxes"):
		for fighter in fighters:
			fighter.debug_boxes = not fighter.debug_boxes
	if Input.is_action_just_pressed("ai"):
		fighters[1].use_ai = not fighters[1].use_ai
		fighters[1].buffer.clear()
		print("Player 2 mode: ", "AI" if fighters[1].use_ai else "LOCAL")
	if round_over:
		return
	if countdown_ticks > 0:
		update_countdown()
		return
	if fight_fade_ticks > 0:
		fight_fade_ticks -= 1
		var countdown: Label = match_overlay.get_node("Countdown")
		countdown.modulate.a = fight_fade_ticks / 30.0
		if fight_fade_ticks == 0:
			countdown.hide()
	for fighter in fighters:
		fighter.tick(delta)
	var separation := fighters[1].position.x - fighters[0].position.x
	if absf(separation) < GameSettings.BODY_WIDTH and fighters[0].hurt_rectangle().intersects(fighters[1].hurt_rectangle()):
		var side := 1.0 if separation >= 0 else -1.0
		var midpoint := clampf(
			(fighters[0].position.x + fighters[1].position.x) / 2,
			GameSettings.LEFT_BOUND + GameSettings.BODY_WIDTH / 2,
			GameSettings.RIGHT_BOUND - GameSettings.BODY_WIDTH / 2
		)
		fighters[0].position.x = midpoint - side * GameSettings.BODY_WIDTH / 2
		fighters[1].position.x = midpoint + side * GameSettings.BODY_WIDTH / 2
	# Preserve both attack results before damage cancels an attack (fair trades).
	var hits: Array[Dictionary] = []
	for fighter in fighters:
		if is_instance_valid(fighter.hitbox) and not fighter.victims.has(fighter.opponent.get_instance_id()):
			if fighter.attack_rectangle().intersects(fighter.opponent.hurt_rectangle()):
				fighter.victims.append(fighter.opponent.get_instance_id())
				hits.append({"attacker": fighter, "target": fighter.opponent, "attack": Fighter.ATTACKS[fighter.combo]})
	for hit in hits:
		hit.target.receive_hit(hit.attack, hit.attacker)
	round_ticks_remaining = maxi(0, round_ticks_remaining - 1)
	if fighters[0].health == 0 or fighters[1].health == 0 or round_ticks_remaining == 0:
		finish_round()
	update_match_hud()

func return_to_menu() -> void:
	for fighter in fighters:
		fighter.enabled = false
	match_audio.reset_match()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		return_to_menu()
