class_name FighterVisual
extends Node2D
## Static Kenney artwork animated by the fighter's simulation frame, not a timer.
var fighter: Fighter
var body: Texture2D
var hand: Texture2D
var shield: Texture2D
var blast: Texture2D

func _ready() -> void:
	fighter = get_parent() as Fighter
	body = load(GameSettings.CHARACTER_TEXTURES[fighter.player_index - 1])
	hand = load(GameSettings.HAND_TEXTURES[fighter.player_index - 1])
	shield = load("res://assets/scribble/item_shieldRound.png")
	blast = load("res://assets/scribble/effect_blast.png")

func _draw() -> void:
	if not is_instance_valid(fighter) or body == null:
		return
	var bob := 0.0
	var tilt := 0.0
	var extension := 0.0
	var active := is_instance_valid(fighter.hitbox)
	match fighter.state:
		Fighter.State.WALKING:
			bob = sin(fighter.state_frame * 0.4) * 3.0
			tilt = sin(fighter.state_frame * 0.2) * 0.08
		Fighter.State.JUMPING:
			tilt = fighter.velocity.x / GameSettings.AIR_SPEED * 0.12
		Fighter.State.ATTACKING:
			var attack: Dictionary = Fighter.ATTACKS[fighter.combo]
			if fighter.state_frame < attack.startup:
				extension = -8.0 * fighter.state_frame / attack.startup
			elif active:
				extension = attack.reach - 12.0
			else:
				var recovery_frame: float = fighter.state_frame - attack.startup - attack.active
				extension = (attack.reach - 12.0) * maxf(0, 1 - recovery_frame / maxf(1, attack.recovery))
			tilt = fighter.facing * (0.12 if active else -0.04)
		Fighter.State.HIT_STUN:
			tilt = sin(fighter.state_frame * 1.2) * 0.15
	var body_color := Color.WHITE
	if fighter.state == Fighter.State.HIT_STUN:
		body_color = Color(1, 0.65, 0.65)
	# Artwork is centered around feet; only visual transforms are mirrored.
	draw_set_transform(Vector2(0, -56 + bob), tilt, Vector2(fighter.facing, 1))
	draw_texture_rect(body, Rect2(-36, -56, 72, 112), false, body_color)
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(hand, Rect2(-fighter.facing * 20 - 32, -82 + bob, 64, 64), false)
	var fist_x := fighter.facing * (24 + extension)
	draw_texture_rect(hand, Rect2(fist_x - 32, -94 + bob, 64, 64), false)
	if active:
		draw_texture_rect(blast, Rect2(fist_x - 18, -80, 36, 36), false, Color(1, 1, 1, 0.8))
	if fighter.state == Fighter.State.BLOCKING:
		draw_texture_rect(shield, Rect2(fighter.facing * 28 - 32, -100, 64, 72), false)
