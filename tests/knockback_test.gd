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
	print("Knockback checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
