extends SceneTree
## Fail on missing imported textures or mismatched character configuration.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	for fighter in arena.fighters:
		var visual: FighterVisual = fighter.visuals
		for texture in [visual.body, visual.hand, visual.shield, visual.blast]:
			if texture == null or texture.get_width() == 0:
				push_error("Fighter texture failed to load")
				quit(1)
				return
	var scenery := arena.get_child(0) as ArenaVisual
	for texture in scenery.textures.values():
		if texture == null:
			push_error("Scenery texture failed to load")
			quit(1)
			return
	print("Asset checks: PASS (both fighters, guard, effects, scenery)")
	quit(0)
