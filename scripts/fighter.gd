class_name Fighter
extends CharacterBody2D
## Fighter FSM and frame-timed combat. Feet are the local origin.

# Jumping is locomotion; hit stun can also occur in the air.
enum State { IDLE, WALKING, ATTACKING, HIT_STUN, BLOCKING, JUMPING }
const SPEED := GameSettings.MOVE_SPEED
const FLOOR_Y := GameSettings.FLOOR_Y
const ATTACKS := GameSettings.ATTACKS
var state: State = State.IDLE
var state_frame := 0
var health := GameSettings.MAX_HEALTH
var facing := 1
var combo := 0
var stun_remaining := 0
var player_index := 1
var opponent: Fighter
var buffer := FightInputBuffer.new()
var hurtbox: Area2D
var hitbox: Area2D
var victims: Array[int] = []
var debug_boxes := true
var enabled := true
var use_ai := false
var ai_timer := 0.0
var visuals: FighterVisual

func _ready() -> void:
	hurtbox = make_area(GameSettings.HURTBOX_SIZE, GameSettings.HURTBOX_CENTER, 1, 0)
	hurtbox.set_meta("fighter", self)
	visuals = FighterVisual.new()
	visuals.z_index = -1 # Keep diagnostic collision boxes above the artwork.
	add_child(visuals)
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

func _input(event: InputEvent) -> void:
	# Capture every press, even multiple presses between physics ticks.
	# Keyboard auto-repeat is not a new command.
	if use_ai or not enabled or event.is_echo():
		return
	var prefix := "p%d_" % player_index
	for command in [&"attack", &"jump"]:
		if event.is_action_pressed(prefix + String(command)):
			buffer.push(command)


func tick(delta: float) -> void:
	buffer.advance(delta)
	if not enabled:
		queue_redraw()
		if is_instance_valid(visuals):
			visuals.queue_redraw()
		return
	var prefix := "p%d_" % player_index
	# Human and AI commands feed the same FSM and input buffer.
	var direction := Input.get_axis(prefix + "left", prefix + "right")
	var blocking := Input.is_action_pressed(prefix + "block")
	if use_ai:
		ai_timer += delta
		var distance := opponent.position.x - position.x
		direction = signf(distance) if absf(distance) > GameSettings.AI_APPROACH_DISTANCE else 0.0
		blocking = opponent.state == State.ATTACKING and fmod(ai_timer, 1.5) < 0.65
		if ai_timer >= GameSettings.AI_ATTACK_INTERVAL:
			ai_timer = 0.0
			if absf(opponent.position.x - position.x) < GameSettings.AI_ATTACK_DISTANCE:
				buffer.push(&"attack")
	if state != State.ATTACKING and state != State.HIT_STUN:
		facing = 1 if opponent.position.x >= position.x else -1
	state_frame += 1
	velocity.x = 0.0
	match state:
		State.HIT_STUN:
			stun_remaining -= 1
			if stun_remaining <= 0:
				change_state(State.IDLE if is_grounded() else State.JUMPING)
		State.JUMPING:
			velocity.x = direction * GameSettings.AIR_SPEED
			if buffer.consume(&"attack"):
				start_attack()
		State.ATTACKING:
			var attack_speed := GameSettings.ATTACK_MOVE_SPEED if is_grounded() else GameSettings.AIR_SPEED
			velocity.x = direction * attack_speed
			var attack: Dictionary = ATTACKS[combo]
			if state_frame == attack.startup:
				hitbox = make_area(
					Vector2(attack.reach, GameSettings.HITBOX_HEIGHT),
					Vector2(facing * (GameSettings.BODY_WIDTH / 2 + attack.reach / 2), GameSettings.HITBOX_Y),
					0, 1
				)
			if state_frame == attack.startup + attack.active:
				remove_hitbox()
			var total: int = attack.startup + attack.active + attack.recovery
			# A buffered press can cancel the final six recovery frames into the next strike.
			var can_chain := combo < ATTACKS.size() - 1
			var in_cancel_window := state_frame >= total - GameSettings.COMBO_CANCEL_FRAMES
			if can_chain and in_cancel_window and buffer.consume(&"attack"):
				start_attack(combo + 1)
			elif state_frame >= total:
				change_state(State.IDLE if is_grounded() else State.JUMPING)
		_:
			if buffer.consume(&"jump"):
				velocity.y = -GameSettings.JUMP_SPEED
				velocity.x = direction * GameSettings.AIR_SPEED
				change_state(State.JUMPING)
				if buffer.consume(&"attack"):
					start_attack()
			elif buffer.consume(&"attack"):
				velocity.x = direction * GameSettings.ATTACK_MOVE_SPEED
				start_attack()
			elif blocking:
				if state != State.BLOCKING:
					change_state(State.BLOCKING)
				velocity.x = direction * GameSettings.BLOCK_MOVE_SPEED
			else:
				var next := State.WALKING if direction != 0 else State.IDLE
				if state != next:
					change_state(next)
				velocity.x = direction * SPEED
	position.x = clampf(position.x + velocity.x * delta, GameSettings.LEFT_BOUND, GameSettings.RIGHT_BOUND)
	# This arena uses an explicit floor plane, not move_and_slide() collisions.
	# Keep vertical momentum during hit stun; only a landing cancels it.
	if not is_grounded() or velocity.y < 0:
		velocity.y += GameSettings.GRAVITY * delta
		position.y += velocity.y * delta
		if position.y >= FLOOR_Y:
			position.y = FLOOR_Y
			velocity.y = 0.0
			if state == State.JUMPING:
				change_state(State.IDLE)
	queue_redraw()
	if is_instance_valid(visuals):
		visuals.queue_redraw()

func is_grounded() -> bool:
	return position.y >= FLOOR_Y and velocity.y >= 0

func attack_rectangle() -> Rect2:
	var attack: Dictionary = ATTACKS[combo]
	var center := global_position + Vector2(facing * (GameSettings.BODY_WIDTH / 2 + attack.reach / 2), GameSettings.HITBOX_Y)
	return Rect2(center - Vector2(attack.reach, GameSettings.HITBOX_HEIGHT) / 2, Vector2(attack.reach, GameSettings.HITBOX_HEIGHT))

func hurt_rectangle() -> Rect2:
	return Rect2(global_position + GameSettings.HURTBOX_CENTER - GameSettings.HURTBOX_SIZE / 2, GameSettings.HURTBOX_SIZE)

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
	health = maxi(0, health - (GameSettings.BLOCK_DAMAGE if guarded else int(attack.damage)))
	change_state(State.HIT_STUN)
	stun_remaining = GameSettings.BLOCK_STUN_FRAMES if guarded else int(attack.stun)
	buffer.clear()
	var push_distance := GameSettings.BLOCK_PUSH if guarded else GameSettings.HIT_PUSH
	position.x = clampf(
		position.x + attacker.facing * push_distance,
		GameSettings.LEFT_BOUND,
		GameSettings.RIGHT_BOUND
	)

func reset_fighter(x: float) -> void:
	change_state(State.IDLE)
	health = GameSettings.MAX_HEALTH
	position = Vector2(x, FLOOR_Y)
	velocity = Vector2.ZERO
	buffer.clear()
	enabled = true
	ai_timer = 0

func _draw() -> void:
	if debug_boxes:
		draw_rect(Rect2(GameSettings.HURTBOX_CENTER - GameSettings.HURTBOX_SIZE / 2, GameSettings.HURTBOX_SIZE), Color(0, 1, 0, 0.55), false, 2)
		if is_instance_valid(hitbox):
			var rect := attack_rectangle()
			rect.position -= global_position
			draw_rect(rect, Color(1, 0.2, 0.2, 0.45), true)
