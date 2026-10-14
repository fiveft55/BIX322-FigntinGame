extends Node2D
## Match coordinator: controls, fighter simulation, simultaneous hits, and HUD.

var fighters: Array[Fighter] = []
var info: Label
var bars: Array[ProgressBar] = []
var round_over := false
var spawn_positions: Array[Vector2] = []

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	for action in GameSettings.KEYS:
		bind(action, GameSettings.KEYS[action])
	fighters.assign([$Fighters/Player1, $Fighters/Player2])
	for fighter in fighters:
		spawn_positions.append(fighter.position)
	fighters[0].opponent = fighters[1]
	fighters[1].opponent = fighters[0]
	create_hud()
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
		fill.bg_color = Color("32b982") if i == 0 else Color("9464df")
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
	info = Label.new()
	info.position = Vector2(45, 125)
	info.add_theme_color_override("font_color", Color("28333b"))
	info.add_theme_font_size_override("font_size", 18)
	layer.add_child(info)
	var help := Label.new()
	help.position = Vector2(45, 555)
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
	help.text = " | ".join(control_labels)
	help.text += "\n%s AI/local · %s hitboxes · %s restart" % [
		GameSettings.key_label("ai"),
		GameSettings.key_label("boxes"),
		GameSettings.key_label("restart"),
	]
	help.add_theme_color_override("font_color", Color("28333b"))
	help.add_theme_font_size_override("font_size", 18)
	layer.add_child(help)

func restart() -> void:
	round_over = false
	for i in range(fighters.size()):
		fighters[i].reset_fighter(spawn_positions[i].x)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart()
	if Input.is_action_just_pressed("boxes"):
		for fighter in fighters:
			fighter.debug_boxes = not fighter.debug_boxes
	if Input.is_action_just_pressed("ai"):
		fighters[1].use_ai = not fighters[1].use_ai
		fighters[1].buffer.clear()
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
	if not round_over and (fighters[0].health == 0 or fighters[1].health == 0):
		round_over = true
		for fighter in fighters:
			fighter.enabled = false
			fighter.remove_hitbox()
	for i in range(2):
		bars[i].value = fighters[i].health
	info.text = "P1: %s   |   P2: %s (%s)\nGreen: hurtbox · Red: active attack · Buffer: %d / %d" % [
		Fighter.State.keys()[fighters[0].state],
		Fighter.State.keys()[fighters[1].state],
		"AI" if fighters[1].use_ai else "LOCAL",
		fighters[0].buffer.commands.size(),
		fighters[1].buffer.commands.size(),
	]
	if round_over:
		var winner := "DRAW" if fighters[0].health == fighters[1].health else "PLAYER %d WINS" % (1 if fighters[1].health == 0 else 2)
		info.text += "\n%s — press %s to restart" % [winner, GameSettings.key_label("restart")]
	queue_redraw()
