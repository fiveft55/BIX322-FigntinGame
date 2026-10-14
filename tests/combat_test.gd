extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for action in ["p1_left", "p1_right", "p1_attack", "p1_block", "p1_jump"]:
		InputMap.add_action(action)
	var buffer := FightInputBuffer.new()
	buffer.push(&"attack")
	buffer.advance(0.1)
	check(buffer.consume(&"attack"), "Buffered input survives short delay")
	check(not buffer.consume(&"attack"), "Input consumed once")
	buffer.push(&"attack")
	buffer.advance(0.23)
	check(not buffer.consume(&"attack"), "Stale input expires")
	var a := Fighter.new()
	var b := Fighter.new()
	root.add_child(a)
	root.add_child(b)
	a.opponent = b
	b.opponent = a
	a.reset_fighter(400)
	b.reset_fighter(480)
	a.start_attack()
	for i in range(5):
		a.tick(1.0 / 60)
	check(a.hitbox == null, "No hitbox during startup")
	a.tick(1.0 / 60)
	check(is_instance_valid(a.hitbox), "Hitbox appears on active frame")
	a.resolve_attack()
	check(b.health == 92 and b.state == Fighter.State.HIT_STUN, "Active hit causes damage and hit stun")
	a.resolve_attack()
	check(b.health == 92, "One hit per target per attack")
	for i in range(4):
		a.tick(1.0 / 60)
	check(a.hitbox == null, "Hitbox removed during recovery")
	for i in range(7):
		a.tick(1.0 / 60)
	a.buffer.push(&"attack")
	a.tick(1.0 / 60)
	check(a.combo == 1 and a.state_frame == 0, "Buffered attack chains during cancel window")
	b.reset_fighter(480)
	b.facing = -1
	b.change_state(Fighter.State.BLOCKING)
	b.receive_hit(Fighter.ATTACKS[0], a)
	check(b.health == 99 and b.stun_remaining == 8, "Front guard reduces damage and stun")
	b.reset_fighter(480)
	b.facing = 1
	b.change_state(Fighter.State.BLOCKING)
	b.receive_hit(Fighter.ATTACKS[0], a)
	check(b.health == 92, "Guard does not protect rear")
	print("Combat checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
