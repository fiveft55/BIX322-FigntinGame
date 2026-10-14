class_name Fighter
extends CharacterBody2D

enum State { IDLE, WALKING, ATTACKING, HIT_STUN, BLOCKING }
const SPEED := 240.0
const FLOOR_Y := 520.0
# Fixed 60 Hz simulation frames: startup, active, recovery, damage, stun, reach.
const ATTACKS := [
	{"startup": 6, "active": 4, "recovery": 13, "damage": 8, "stun": 18, "reach": 64.0},
	{"startup": 7, "active": 4, "recovery": 14, "damage": 10, "stun": 21, "reach": 72.0},
	{"startup": 10, "active": 5, "recovery": 22, "damage": 16, "stun": 27, "reach": 90.0}
]
var state: State = State.IDLE
var state_frame := 0
var health := 100
var facing := 1
var combo := 0
var stun_remaining := 0
var player_index := 1
var tint := Color.CYAN
var opponent: Fighter
var buffer := FightInputBuffer.new()
var hurtbox: Area2D
var hitbox: Area2D
var hit_shape: CollisionShape2D
var victims: Array[int] = []
var debug_boxes := true
var enabled := true
var use_ai := false
var ai_timer := 0.0

func _ready() -> void:
	hurtbox = make_area(Vector2(42, 104), Vector2(0, -54), 1, 0)
	hurtbox.set_meta("fighter", self)
	set_physics_process(false) # Arena updates both fighters before resolving collisions.

func make_area(size: Vector2, center: Vector2, layer: int, mask: int) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = layer
	area.collision_mask = mask
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.position = center
	area.add_child(shape)
	add_child(area)
	return area

func change_state(next: State) -> void:
	if state == State.ATTACKING:
		remove_hitbox()
	state = next
	state_frame = 0

func start_attack(next_combo: int = 0) -> void:
	change_state(State.ATTACKING)
	combo = next_combo
	victims.clear()

func remove_hitbox() -> void:
	if is_instance_valid(hitbox):
		remove_child(hitbox)
		hitbox.queue_free()
	hitbox = null

func tick(delta: float) -> void:
	buffer.advance(delta)
	if not enabled:
		queue_redraw()
		return
	var prefix := "p%d_" % player_index
	var direction := Input.get_axis(prefix + "left", prefix + "right")
	var blocking := Input.is_action_pressed(prefix + "block")
	if use_ai:
		ai_timer += delta
		direction = signf(opponent.position.x - position.x) if absf(opponent.position.x - position.x) > 105 else 0.0
		blocking = opponent.state == State.ATTACKING and fmod(ai_timer, 1.5) < 0.65
		if ai_timer >= 0.6:
			ai_timer = 0.0
			if absf(opponent.position.x - position.x) < 145:
				buffer.push(&"attack")
	elif Input.is_action_just_pressed(prefix + "attack"):
		buffer.push(&"attack")
	if state != State.ATTACKING and state != State.HIT_STUN:
		facing = 1 if opponent.position.x >= position.x else -1
	state_frame += 1
	velocity = Vector2.ZERO
	match state:
		State.HIT_STUN:
			stun_remaining -= 1
			if stun_remaining <= 0:
				change_state(State.IDLE)
		State.ATTACKING:
			var attack: Dictionary = ATTACKS[combo]
			if state_frame == attack.startup:
				hitbox = make_area(Vector2(attack.reach, 36), Vector2(facing * (22 + attack.reach / 2), -62), 0, 1)
			if state_frame == attack.startup + attack.active:
				remove_hitbox()
			var total: int = attack.startup + attack.active + attack.recovery
			# A buffered press can cancel the final six recovery frames into the next strike.
			if combo < 2 and state_frame >= total - 6 and buffer.consume(&"attack"):
				start_attack(combo + 1)
			elif state_frame >= total:
				change_state(State.IDLE)
		_:
			if blocking:
				if state != State.BLOCKING:
					change_state(State.BLOCKING)
			elif buffer.consume(&"attack"):
				start_attack()
			else:
				var next := State.WALKING if direction != 0 else State.IDLE
				if state != next:
					change_state(next)
				velocity.x = direction * SPEED
	position.x = clampf(position.x + velocity.x * delta, 42, 1110)
	position.y = FLOOR_Y
	queue_redraw()

func attack_rectangle() -> Rect2:
	var attack: Dictionary = ATTACKS[combo]
	var center := global_position + Vector2(facing * (22 + attack.reach / 2), -62)
	return Rect2(center - Vector2(attack.reach, 36) / 2, Vector2(attack.reach, 36))

func hurt_rectangle() -> Rect2:
	return Rect2(global_position + Vector2(-21, -106), Vector2(42, 104))

func resolve_attack() -> void:
	# Resolve the same rectangles used by Area2D, avoiding deferred physics overlap
	# updates when an active hitbox is created during this simulation tick.
	if not is_instance_valid(hitbox) or victims.has(opponent.get_instance_id()):
		return
	if attack_rectangle().intersects(opponent.hurt_rectangle()):
		victims.append(opponent.get_instance_id())
		opponent.receive_hit(ATTACKS[combo], self)

func receive_hit(attack: Dictionary, attacker: Fighter) -> void:
	var front := signf(attacker.position.x - position.x) == facing
	var guarded := state == State.BLOCKING and front
	health = maxi(0, health - (1 if guarded else int(attack.damage)))
	change_state(State.HIT_STUN)
	stun_remaining = 8 if guarded else int(attack.stun)
	buffer.clear()
	position.x = clampf(position.x + attacker.facing * (8 if guarded else 18), 42, 1110)

func reset_fighter(x: float) -> void:
	change_state(State.IDLE)
	health = 100
	position = Vector2(x, FLOOR_Y)
	buffer.clear()
	enabled = true
	ai_timer = 0

func _draw() -> void:
	var color := tint
	if state == State.HIT_STUN:
		color = Color.WHITE
	draw_line(Vector2(-13, -36), Vector2(-20, 0), color, 12)
	draw_line(Vector2(13, -36), Vector2(20, 0), color, 12)
	draw_style_box(body_style(color), Rect2(-22, -90, 44, 60))
	draw_circle(Vector2(0, -111), 19, color)
	draw_circle(Vector2(facing * 7, -114), 3, Color("10152b"))
	var hand := Vector2(facing * 32, -65)
	if state == State.ATTACKING:
		hand.x = facing * (48 if hitbox == null else 82)
	draw_line(Vector2(0, -78), hand, color, 12)
	draw_circle(hand, 9, Color.WHITE)
	if state == State.BLOCKING:
		draw_arc(Vector2(facing * 15, -65), 44, -PI / 2 if facing == 1 else PI / 2, PI / 2 if facing == 1 else PI * 1.5, 24, Color("ffd76d"), 5)
	if debug_boxes:
		draw_rect(Rect2(-21, -106, 42, 104), Color(0, 1, 0, 0.55), false, 2)
		if is_instance_valid(hitbox):
			var rect := attack_rectangle()
			rect.position -= global_position
			draw_rect(rect, Color(1, 0.2, 0.2, 0.45), true)

func body_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.2)
	style.set_corner_radius_all(8)
	return style
