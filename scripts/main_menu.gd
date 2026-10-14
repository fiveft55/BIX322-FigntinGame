extends Control
## Scene-authored menu with saved audio/difficulty options and readable controls.
@onready var music: AudioStreamPlayer = $Music
@onready var start_sound: AudioStreamPlayer = $StartSound
@onready var home: Panel = $Home
@onready var options: Panel = $Settings
@onready var character_page: Panel = $Characters
@onready var controls: Panel = $Controls
var starting := false

func _ready() -> void:
	music.stream = music.stream.duplicate()
	music.stream.loop = true
	music.play()
	$Home/Difficulty.select(Preferences.difficulty)
	$Home/Difficulty.item_selected.connect(set_difficulty)
	$Home/PlayAI.pressed.connect(func() -> void: start_game(false))
	$Home/PlayLocal.pressed.connect(func() -> void: start_game(true))
	$Home/SettingsButton.pressed.connect(func() -> void: show_page(options))
	$Home/CharactersButton.pressed.connect(func() -> void: show_page(character_page))
	$Characters/Back.pressed.connect(func() -> void: show_page(home))
	configure_characters()
	$Home/ControlsButton.pressed.connect(func() -> void: show_page(controls))
	$Home/Quit.pressed.connect(func() -> void: get_tree().quit())
	$Settings/Back.pressed.connect(func() -> void: show_page(home))
	$Controls/Back.pressed.connect(func() -> void: show_page(home))
	for kind in ["Music", "Effects", "Voice"]:
		var slider: HSlider = options.get_node(kind + "Slider")
		slider.value = Preferences.get(kind.to_lower() + "_volume") * 100
		slider.value_changed.connect(func(value: float) -> void: set_volume(kind, value))
		update_volume_label(kind, slider.value)
	update_controls()
	show_page(home)

func set_difficulty(index: int) -> void:
	Preferences.difficulty = index
	Preferences.save_settings()

func set_volume(kind: String, value: float) -> void:
	Preferences.set(kind.to_lower() + "_volume", value / 100.0)
	Preferences.apply_volumes()
	Preferences.save_settings()
	update_volume_label(kind, value)

func update_volume_label(kind: String, value: float) -> void:
	options.get_node(kind + "Label").text = "%s   %d%%" % [kind, roundi(value)]

func show_page(page: Panel) -> void:
	home.visible = page == home
	options.visible = page == options
	controls.visible = page == controls
	character_page.visible = page == character_page
	if page == home:
		$Home/PlayAI.grab_focus()
	else:
		page.get_node("Back").grab_focus()

func update_controls() -> void:
	var text := ""
	for player in ["p1", "p2"]:
		text += "%s\n%s / %s — Move     %s — Jump\n%s — Sword attack / combo     %s — Hold shield\n\n" % [
			player.to_upper(), GameSettings.key_label(player + "_left"),
			GameSettings.key_label(player + "_right"), GameSettings.key_label(player + "_jump"),
			GameSettings.key_label(player + "_attack"), GameSettings.key_label(player + "_block")]
	text += "AI matches only: %s restart · %s AI toggle\nAI matches only: %s collision diagnostics     Esc — Main menu\n\nMove + jump + attack can combine. Front blocks parry.\nMatches last 60 seconds; greater health wins on timeout." % [
		GameSettings.key_label("restart"), GameSettings.key_label("ai"), GameSettings.key_label("boxes")]
	$Controls/Info.text = text

func start_game(local: bool) -> void:
	if starting:
		return
	starting = true
	Preferences.local_mode = local
	for button in home.find_children("*", "Button", false, false):
		button.disabled = true
	music.stop()
	start_sound.play()
	# A brief transition plays the supplied cue without delaying the fight too long.
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/arena.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not starting:
		show_page(home)

func _exit_tree() -> void:
	music.stop()
	start_sound.stop()

func configure_characters() -> void:
	for slot in range(2):
		var column := character_page.get_node("Player%d" % (slot + 1))
		var character_choice: OptionButton = column.get_node("Character")
		var weapon_choice: OptionButton = column.get_node("Weapon")
		var hat_choice: OptionButton = column.get_node("Hat")
		for character in GameSettings.CHARACTERS:
			character_choice.add_item(character.name)
		for weapon in GameSettings.WEAPONS:
			weapon_choice.add_item(weapon.name)
		for hat in GameSettings.HATS:
			hat_choice.add_item(hat.name)
		hat_choice.select(Preferences.hats[slot])
		hat_choice.item_selected.connect(func(index: int) -> void: choose_hat(slot, index))
		character_choice.select(Preferences.characters[slot])
		weapon_choice.select(Preferences.weapons[slot])
		character_choice.item_selected.connect(func(index: int) -> void: choose_character(slot, index))
		weapon_choice.item_selected.connect(func(index: int) -> void: choose_weapon(slot, index))
		update_preview(slot)

func choose_character(slot: int, index: int) -> void:
	Preferences.characters[slot] = index
	Preferences.save_settings()
	update_preview(slot)

func choose_weapon(slot: int, index: int) -> void:
	Preferences.weapons[slot] = index
	Preferences.save_settings()
	update_preview(slot)

func update_preview(slot: int) -> void:
	var column := character_page.get_node("Player%d" % (slot + 1))
	var character: Dictionary = GameSettings.CHARACTERS[Preferences.characters[slot]]
	column.get_node("Preview/Body").texture = load(character.body)
	column.get_node("Preview/Hand").texture = load(character.hand)
	column.get_node("Preview/Hand/Weapon").texture = load(GameSettings.WEAPONS[Preferences.weapons[slot]].texture)
	column.get_node("ColorBar").color = character.color
	var hat: Sprite2D = column.get_node("Preview/Body/Hat")
	var path: String = GameSettings.HATS[Preferences.hats[slot]].texture
	hat.visible = not path.is_empty()
	hat.texture = load(path) if hat.visible else null

func choose_hat(slot: int, index: int) -> void:
	Preferences.hats[slot] = index
	Preferences.save_settings()
	update_preview(slot)
