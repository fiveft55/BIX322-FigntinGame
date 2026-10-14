extends Node
## Persistent user options. Values are normalized 0..1 linear bus gains.
const SAVE_PATH := "user://settings.cfg"
var settings_path := SAVE_PATH
var difficulty := 1
var local_mode := false
var characters: Array[int] = [0, 5]
var weapons: Array[int] = [0, 0]
var music_volume := 1.0
var effects_volume := 1.0
var voice_volume := 1.0

func _ready() -> void:
	load_settings()
	apply_volumes()

func load_settings(path: String = "") -> void:
	if path.is_empty():
		path = settings_path
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	difficulty = clampi(int(config.get_value("game", "difficulty", 1)), 0, 2)
	for player in range(2):
		characters[player] = clampi(int(config.get_value("players", "character_%d" % player, characters[player])), 0, GameSettings.CHARACTERS.size() - 1)
		weapons[player] = clampi(int(config.get_value("players", "weapon_%d" % player, 0)), 0, GameSettings.WEAPONS.size() - 1)
	music_volume = clampf(float(config.get_value("audio", "music", 1.0)), 0, 1)
	effects_volume = clampf(float(config.get_value("audio", "effects", 1.0)), 0, 1)
	voice_volume = clampf(float(config.get_value("audio", "voice", 1.0)), 0, 1)

func save_settings(path: String = "") -> Error:
	if path.is_empty():
		path = settings_path
	var config := ConfigFile.new()
	config.set_value("game", "difficulty", difficulty)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "effects", effects_volume)
	config.set_value("audio", "voice", voice_volume)
	for player in range(2):
		config.set_value("players", "character_%d" % player, characters[player])
		config.set_value("players", "weapon_%d" % player, weapons[player])
	return config.save(path)

func apply_volumes() -> void:
	for pair in [["Music", music_volume], ["SFX", effects_volume], ["Voice", voice_volume]]:
		var index := AudioServer.get_bus_index(pair[0])
		if index >= 0:
			AudioServer.set_bus_mute(index, pair[1] <= 0)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(pair[1], 0.0001)))
