class_name MatchAudio
extends Node
## Audio routing is scene-editable; fighter signals trigger overlapping effects.
@export var sword_sound: AudioStream
@export var hit_sound: AudioStream
@export var block_sound: AudioStream
@export var jump_sound: AudioStream
@export var game_over_sound: AudioStream
@export var countdown_three: AudioStream
@export var countdown_two: AudioStream
@export var countdown_one: AudioStream
@export var fight_voice: AudioStream
@export var player_one_voice: AudioStream
@export var player_two_voice: AudioStream
@export var winner_voice: AudioStream
@export var tie_voice: AudioStream
@export var time_voice: AudioStream
@onready var knockout: AudioStreamPlayer = $Knockout
@onready var music: AudioStreamPlayer = $Music
@onready var voice: AudioStreamPlayer = $Announcer
@onready var effect_template: AudioStreamPlayer = $Effects
var effect_players: Array[AudioStreamPlayer] = []
var voice_queue: Array[AudioStream] = []
var last_event := ""

func _ready() -> void:
	# Duplicate so enabling looping never modifies the imported shared resource.
	music.stream = music.stream.duplicate()
	if music.stream is AudioStreamMP3:
		music.stream.loop = true
	for i in range(8):
		var player := effect_template.duplicate() as AudioStreamPlayer
		add_child(player)
		effect_players.append(player)
	voice.finished.connect(play_next_voice)

func reset_match() -> void:
	knockout.stop()
	music.stop()
	voice.stop()
	voice_queue.clear()
	for player in effect_players:
		player.stop()
	last_event = ""

func _exit_tree() -> void:
	reset_match()
	knockout.stream = null
	music.stream = null
	voice.stream = null
	for player in effect_players:
		player.stream = null

func say(stream: AudioStream) -> void:
	# Countdown announcements replace any previous countdown clip.
	voice_queue.clear()
	voice.stop()
	voice.stream = stream
	if stream != null:
		voice.play()

func begin_battle() -> void:
	music.play()
	say(fight_voice)

func play_next_voice() -> void:
	if voice_queue.is_empty():
		return
	voice.stream = voice_queue.pop_front()
	voice.play()

func play_effect(stream: AudioStream) -> void:
	if stream == null:
		return
	var player := effect_players[0]
	for candidate in effect_players:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.play()

func on_combat_sound(event: StringName) -> void:
	last_event = String(event)
	match event:
		&"sword": play_effect(sword_sound)
		&"hit": play_effect(hit_sound)
		&"block": play_effect(block_sound)
		&"jump": play_effect(jump_sound)

func play_knockout() -> void:
	# Dedicated player lets the hurt cue finish beneath the later result voice.
	last_event = "knockout"
	knockout.play()

func finish_match(winner: int, timed_out: bool) -> void:
	music.stop()
	voice.stop()
	voice_queue.clear()
	for player in effect_players:
		player.stop()
	if timed_out:
		voice_queue.append(time_voice)
	else:
		play_effect(game_over_sound)
	if winner == 0:
		voice_queue.append(tie_voice)
	else:
		voice_queue.append(player_one_voice if winner == 1 else player_two_voice)
		voice_queue.append(winner_voice)
	play_next_voice()
