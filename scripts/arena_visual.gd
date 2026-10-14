class_name ArenaVisual
extends Node2D
## Decorative scenery only. The floor remains the combat simulation's plane.
const ART := "res://assets/scribble/"
var textures: Dictionary = {}

func _ready() -> void:
	for name in ["background_cloudA", "background_cloudB", "background_tree", "background_treeLarge", "tile_grass", "tile_brick", "tile_bush", "tile_castle"]:
		textures[name] = load(ART + name + ".png")
	queue_redraw()

func stamp(name: String, rectangle: Rect2, color := Color.WHITE) -> void:
	draw_texture_rect(textures[name], rectangle, false, color)

func _draw() -> void:
	if textures.is_empty():
		return
	draw_rect(Rect2(0, 0, 1152, 648), Color("f8f5eb"))
	# Notebook lines support the hand-drawn style without hiding the characters.
	for y in range(200, int(GameSettings.FLOOR_Y), 32):
		draw_line(Vector2(0, y), Vector2(1152, y), Color("e4e7e2"), 1)
	stamp("background_cloudA", Rect2(95, 190, 220, 95))
	stamp("background_cloudB", Rect2(760, 185, 250, 110))
	stamp("background_treeLarge", Rect2(15, GameSettings.FLOOR_Y - 220, 145, 220))
	stamp("background_tree", Rect2(1000, GameSettings.FLOOR_Y - 190, 110, 190))
	stamp("tile_castle", Rect2(160, GameSettings.FLOOR_Y - 125, 130, 125), Color(1, 1, 1, 0.65))
	stamp("tile_castle", Rect2(860, GameSettings.FLOOR_Y - 125, 130, 125), Color(1, 1, 1, 0.65))
	stamp("tile_bush", Rect2(290, GameSettings.FLOOR_Y - 52, 90, 52))
	stamp("tile_bush", Rect2(780, GameSettings.FLOOR_Y - 52, 90, 52))
	# Tile tops align exactly with the fighter foot plane.
	for x in range(0, 1152, 64):
		stamp("tile_grass", Rect2(x, GameSettings.FLOOR_Y, 64, 64))
		stamp("tile_brick", Rect2(x, GameSettings.FLOOR_Y + 64, 64, 64))
