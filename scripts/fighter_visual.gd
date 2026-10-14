class_name FighterVisual
extends Node2D
## Scene-authored sprites; gameplay supplies pose offsets, never texture paths.
@onready var fighter := get_parent() as Fighter
@onready var rig: Node2D = $Rig
@onready var body: Sprite2D = $Rig/Body
@onready var front_hand: Sprite2D = $Rig/FrontHand
@onready var rear_hand: Sprite2D = $Rig/RearHand
@onready var shield: Sprite2D = $Rig/RearHand/Shield
## Tune the shield-hand guard pose in the Visuals Inspector.
@export var guard_hand_offset := Vector2(48, -18)
@export_range(1, 30, 1) var guard_raise_frames := 6
@export var guard_recoil_offset := Vector2(-10, 4)
var base_rear_rotation := 0.0
@onready var effect: Sprite2D = $Rig/PunchEffect
@onready var sword: Sprite2D = $Rig/FrontHand/SwordGrip/Sword
var base_positions: Dictionary = {}
var base_body_rotation := 0.0
@onready var sword_grip: Node2D = $Rig/FrontHand/SwordGrip
var base_sword_rotation := 0.0

func _ready() -> void:
	for node in [body, front_hand, rear_hand, effect]:
		base_positions[node] = node.position
	base_rear_rotation = rear_hand.rotation
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
	body.modulate = Color(1, 0.65, 0.65) if fighter.state == Fighter.State.HIT_STUN and not fighter.guard_hit else Color.WHITE
	front_hand.position = base_positions[front_hand] + Vector2(extension, bob)
	sword_grip.rotation = base_sword_rotation + swing
	effect.position = base_positions[effect] + Vector2(Fighter.ATTACKS[fighter.combo].reach - 24, 0)
	effect.visible = active
	# Shield is a child of the free hand, so it follows every hand transform.
	var guard_amount := 0.0
	var recoil := 0.0
	if fighter.state == Fighter.State.BLOCKING:
		guard_amount = clampf(float(fighter.state_frame) / guard_raise_frames, 0, 1)
	elif fighter.state == Fighter.State.HIT_STUN and fighter.guard_hit:
		guard_amount = 1.0
		recoil = maxf(0, 1 - float(fighter.state_frame) / GameSettings.BLOCK_STUN_FRAMES)
	rear_hand.position = base_positions[rear_hand] + Vector2(0, bob)
	rear_hand.position += guard_hand_offset * guard_amount + guard_recoil_offset * recoil
	rear_hand.rotation = base_rear_rotation - 0.15 * guard_amount + 0.2 * recoil
	shield.visible = not fighter.equipment_detached
	sword.visible = not fighter.equipment_detached
