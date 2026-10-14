class_name GameSettings
extends RefCounted
## Edit this file to tune gameplay. Units: pixels, seconds, or 60 Hz frames.
const MOVE_SPEED := 240.0 # Horizontal pixels per second.
const ATTACK_MOVE_SPEED := 120.0 # Movement while attacking on the ground.
const BLOCK_MOVE_SPEED := 90.0 # Movement while guarding.
const ATTACK_INPUT_WINDOW := 0.75 # Mash presses survive startup and recovery.
const AIR_SPEED := 210.0 # Horizontal control while jumping.
const JUMP_SPEED := 620.0 # Positive magnitude; applied upward as negative Y.
const GRAVITY := 1800.0 # Downward pixels per second squared.
const MAX_HEALTH := 100
const FLOOR_Y := 520.0 # Fighter foot position when grounded.
const LEFT_BOUND := 42.0
const RIGHT_BOUND := 1110.0
const BODY_WIDTH := 44.0
const HURTBOX_SIZE := Vector2(42, 104)
const HURTBOX_CENTER := Vector2(0, -54)
const HITBOX_HEIGHT := 36.0
const HITBOX_Y := -62.0
const INPUT_WINDOW := 0.22
const MAX_BUFFER_COMMANDS := 8
const COMBO_CANCEL_FRAMES := 6
const BLOCK_DAMAGE := 1
const BLOCK_STUN_FRAMES := 8
const HIT_PUSH := 18.0
const BLOCK_PUSH := 8.0
const AI_APPROACH_DISTANCE := 105.0
const AI_ATTACK_DISTANCE := 145.0
const AI_ATTACK_INTERVAL := 0.6
const SPAWN_POSITIONS := [400.0, 750.0]
const ATTACKS := [
	{"startup": 6, "active": 4, "recovery": 13, "damage": 8, "stun": 18, "reach": 64.0},
	{"startup": 7, "active": 4, "recovery": 14, "damage": 10, "stun": 21, "reach": 72.0},
	{"startup": 10, "active": 5, "recovery": 22, "damage": 16, "stun": 27, "reach": 90.0}
]
## Physical keyboard keys. Restart the game after editing. Avoid duplicates.
const KEYS := {
	"p1_left": KEY_A, "p1_right": KEY_D, "p1_jump": KEY_W,
	"p1_attack": KEY_F, "p1_block": KEY_G,
	"p2_left": KEY_LEFT, "p2_right": KEY_RIGHT, "p2_jump": KEY_UP,
	"p2_attack": KEY_K, "p2_block": KEY_L,
	"restart": KEY_R, "boxes": KEY_H, "ai": KEY_TAB
}

static func key_label(action: String) -> String:
	return OS.get_keycode_string(KEYS[action])

## Uploaded Kenney art. Arrays are indexed by player number minus one.
const CHARACTER_TEXTURES := [
	"res://assets/scribble/character_roundGreen.png",
	"res://assets/scribble/character_squarePurple.png",
]
const HAND_TEXTURES := [
	"res://assets/scribble/character_handGreen.png",
	"res://assets/scribble/character_handPurple.png",
]
