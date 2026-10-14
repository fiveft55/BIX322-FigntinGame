extends Node2D
## Match coordinator: controls, fighter simulation, simultaneous hits, and HUD.

var fighters: Array[Fighter] = []
var info: Label
var bars: Array[ProgressBar] = []
var round_over := false

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	for action in GameSettings.KEYS:
		bind(action, GameSettings.KEYS[action])
	for i in range(2):
		var fighter := Fighter.new()
		fighter.player_index = i + 1
		fighter.tint = Color("55e0ee") if i == 0 else Color("fa7098")
		add_child(fighter)
		fighters.append(fighter)
	fighters[0].opponent = fighters[1]
	fighters[1].opponent = fighters[0]
	fighters[1].use_ai = true
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
	title.text = "FRAME FIGHTERS"
	title.position = Vector2(410, 20)
	title.add_theme_font_size_override("font_size", 32)
	layer.add_child(title)
	for i in range(2):
		var bar := ProgressBar.new()
		bar.position = Vector2(45 if i == 0 else 727, 85)
		bar.size = Vector2(380, 26)
		bar.max_value = GameSettings.MAX_HEALTH
		bar.show_percentage = false
		layer.add_child(bar)
		bars.append(bar)
	info = Label.new()
	info.position = Vector2(45, 125)
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
	help.add_theme_font_size_override("font_size", 18)
	layer.add_child(help)

func restart() -> void:
	round_over = false
	fighters[0].reset_fighter(GameSettings.SPAWN_POSITIONS[0])
	fighters[1].reset_fighter(GameSettings.SPAWN_POSITIONS[1])

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

func _draw() -> void:
	for x in range(0, 1152, 64):
		draw_line(Vector2(x, 200), Vector2(x, GameSettings.FLOOR_Y), Color(0.12, 0.16, 0.25), 1)
	draw_rect(Rect2(0, GameSettings.FLOOR_Y, 1152, 648 - GameSettings.FLOOR_Y), Color("121d33"))
	draw_line(Vector2(0, GameSettings.FLOOR_Y + 1), Vector2(1152, GameSettings.FLOOR_Y + 1), Color("55e0ee"), 3)
