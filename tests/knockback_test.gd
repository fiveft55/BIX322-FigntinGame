extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for action in ["p1_left", "p1_right", "p1_block"]:
		InputMap.add_action(action)
	var attacker := Fighter.new()
	var target := Fighter.new()
	root.add_child(attacker)
	root.add_child(target)
	attacker.opponent = target
	target.opponent = attacker
	attacker.reset_fighter(400)
	target.reset_fighter(500)
	target.hit_push_distance = 120
	target.hit_jump_speed = 300
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	check(target.velocity.y == -300, "Hit applies editable upward launch")
	target.tick(1.0 / 60)
	check(target.position.x > 500 and target.position.y < GameSettings.FLOOR_Y, "Hit moves backward and upward")
	for frame in range(17):
		target.tick(1.0 / 60)
	check(is_equal_approx(target.position.x, 620), "Configured knockback distance is delivered over stun")
	for frame in range(60):
		target.tick(1.0 / 60)
	check(target.is_grounded(), "Hit hop lands safely")
	target.reset_fighter(300)
	target.hit_push_distance = 40
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	for frame in range(18):
		target.tick(1.0 / 60)
	check(is_equal_approx(target.position.x, 260), "Different distance and opposite direction work")
	target.reset_fighter(500)
	target.facing = -1
	target.change_state(Fighter.State.BLOCKING)
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	check(target.velocity.y == 0 and target.knockback_remaining == 0, "Guard has no hit hop")
	target.reset_fighter(GameSettings.RIGHT_BOUND - 2)
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	for frame in range(18):
		target.tick(1.0 / 60)
	check(target.position.x == GameSettings.RIGHT_BOUND, "Arena wall limits knockback")
	target.reset_fighter(500)
	check(target.velocity == Vector2.ZERO and target.knockback_remaining == 0, "Reset clears knockback momentum")
	target.hit_push_distance = GameSettings.HIT_PUSH
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	check(target.stun_remaining == 24, "Default stun lasts 0.4 seconds at 60 Hz")
	Input.action_press("p1_left")
	target.buffer.push(&"attack")
	target.buffer.push(&"jump")
	for frame in range(18):
		target.tick(1.0 / 60)
	check(is_equal_approx(target.position.x, 680), "Stronger default knockback travels 180 pixels")
	for frame in range(5):
		target.tick(1.0 / 60)
	check(target.state == Fighter.State.HIT_STUN and target.stun_remaining == 1, "Movement, attack, and jump cannot interrupt 0.4-second stun")
	check(is_equal_approx(target.position.x, 680), "Knockback stops while stun remains")
	target.tick(1.0 / 60)
	check(target.state == Fighter.State.IDLE, "Stun ends after the twenty-fourth tick")
	Input.action_release("p1_left")
	target.reset_fighter(500)
	target.hit_stun_seconds = 0.75
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	check(target.stun_remaining == 45, "Inspector stun duration is editable")
	attacker.reset_fighter(400)
	target.reset_fighter(500)
	attacker.facing = 1
	attacker.start_attack()
	for frame in range(ceili(Fighter.ATTACKS[0].startup / GameSettings.ATTACK_SPEED)):
		attacker.tick(1.0 / 60)
	target.facing = -1
	target.change_state(Fighter.State.BLOCKING)
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	check(attacker.state == Fighter.State.HIT_STUN and attacker.hitbox == null, "Front block parries and interrupts the attacker")
	check(attacker.health == GameSettings.MAX_HEALTH and attacker.stun_remaining == 24, "Parry deals no damage and stuns for 0.4 seconds")
	for frame in range(18):
		attacker.tick(1.0 / 60)
	check(is_equal_approx(attacker.position.x, 280), "Parry pushes attacker away by editable distance")
	attacker.reset_fighter(600)
	target.reset_fighter(500)
	target.facing = -1
	target.change_state(Fighter.State.BLOCKING)
	target.receive_hit(GameSettings.ATTACKS[0], attacker)
	check(attacker.state == Fighter.State.IDLE, "Rear hit cannot trigger a parry")
	print("Knockback checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
