extends Sprite2D
## Scene-editable direction/speed; wrapping occurs only once the cloud is offscreen.
@export var drift_speed := 10.0

func _physics_process(delta: float) -> void:
	position.x += drift_speed * delta
	var half_width := texture.get_width() * absf(scale.x) / 2
	var width := get_viewport_rect().size.x
	if position.x > width + half_width:
		position.x = -half_width
	elif position.x < -half_width:
		position.x = width + half_width
