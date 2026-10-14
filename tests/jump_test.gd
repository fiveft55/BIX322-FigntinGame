extends SceneTree
## Exercise the real input map and arena tick, rather than a separate jump formula.
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	var fighter: Fighter = arena.fighters[0]
	var opponent: Fighter = arena.fighters[1]
	opponent.use_ai = false
	# Just-pressed flags are sampled in the physics domain by fighter.tick().
	await physics_frame
	Input.action_press("p1_jump")
	Input.action_press("p1_right")
	await physics_frame
	arena._physics_process(1.0 / 60)
	Input.action_release("p1_jump")
	await physics_frame
	check(fighter.state == Fighter.State.JUMPING and fighter.position.y < GameSettings.FLOOR_Y, "Jump key launches fighter")
	check(fighter.position.x > GameSettings.SPAWN_POSITIONS[0], "Air steering moves horizontally")
	var previous_velocity := fighter.velocity.y
	fighter.buffer.push(&"jump")
	arena._physics_process(1.0 / 60)
	check(fighter.velocity.y > previous_velocity, "Airborne jump cannot reset upward velocity")
	Input.action_release("p1_right")
	for frame in range(80):
		arena._physics_process(1.0 / 60)
	check(fighter.is_grounded() and fighter.position.y == GameSettings.FLOOR_Y and fighter.velocity.y == 0, "Jump lands without floor penetration")
	check(fighter.state == Fighter.State.IDLE, "Landing restores idle state")
	fighter.reset_fighter(400)
	opponent.reset_fighter(480)
	fighter.buffer.push(&"jump")
	for frame in range(14):
		fighter.tick(1.0 / 60)
	opponent.facing = -1
	opponent.start_attack()
	for frame in range(6):
		opponent.tick(1.0 / 60)
	opponent.resolve_attack()
	check(fighter.health == GameSettings.MAX_HEALTH, "High jump avoids grounded attack by vertical hurtbox separation")
	fighter.receive_hit(GameSettings.ATTACKS[0], opponent)
	check(fighter.state == Fighter.State.HIT_STUN, "Airborne hit enters hit stun")
	for frame in range(80):
		fighter.tick(1.0 / 60)
	check(fighter.is_grounded() and fighter.state == Fighter.State.IDLE, "Gravity continues through airborne stun and lands safely")
	fighter.buffer.push(&"jump")
	fighter.tick(1.0 / 60)
	arena.restart()
	check(fighter.velocity == Vector2.ZERO and fighter.is_grounded(), "Restart clears jump momentum")
	print("Jump checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
