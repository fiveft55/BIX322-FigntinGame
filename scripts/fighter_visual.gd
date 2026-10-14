class_name FighterVisual
extends Node2D
## Scene-authored sprites; gameplay supplies pose offsets, never texture paths.
@onready var fighter := get_parent() as Fighter
@onready var rig: Node2D = $Rig
@onready var body: Sprite2D = $Rig/Body
@onready var front_hand: Sprite2D = $Rig/FrontHand
@onready var shield: Sprite2D = $Rig/Shield
@onready var effect: Sprite2D = $Rig/PunchEffect
@onready var sword: Sprite2D = $Rig/FrontHand/SwordGrip/Sword
var base_positions: Dictionary = {}
var base_body_rotation := 0.0
@onready var sword_grip: Node2D = $Rig/FrontHand/SwordGrip
var base_sword_rotation := 0.0

func _ready() -> void:
	for node in [body, front_hand, effect]:
		base_positions[node] = node.position
	base_body_rotation = body.rotation
	base_sword_rotation = sword_grip.rotation
	update_pose()

func update_pose() -> void:
	var bob := 0.0
	var tilt := 0.0
	var extension := 0.0
	var swing := -0.6
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
				var progress: float = float(fighter.state_frame) / attack.startup
				extension = -8.0 * progress
				swing = -0.6 - progress * 0.6
			elif active:
				extension = 12.0
				swing = 0.0
			else:
				var elapsed: float = fighter.state_frame - attack.startup - attack.active
				var progress := clampf(elapsed / maxf(1, attack.recovery), 0, 1)
				extension = 12.0 * (1 - progress)
				swing = -0.6 * progress
			tilt = 0.1 if active else -0.04
		Fighter.State.HIT_STUN:
			tilt = sin(fighter.state_frame * 1.2) * 0.15
	rig.scale.x = fighter.facing
	body.position = base_positions[body] + Vector2(0, bob)
	body.rotation = base_body_rotation + tilt
	body.modulate = Color(1, 0.65, 0.65) if fighter.state == Fighter.State.HIT_STUN else Color.WHITE
	front_hand.position = base_positions[front_hand] + Vector2(extension, bob)
	sword_grip.rotation = base_sword_rotation + swing
	effect.position = base_positions[effect] + Vector2(Fighter.ATTACKS[fighter.combo].reach - 24, 0)
	effect.visible = active
	shield.visible = fighter.state == Fighter.State.BLOCKING
