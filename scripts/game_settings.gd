class_name GameSettings
extends RefCounted
## Edit this file to tune gameplay. Units: pixels, seconds, or 60 Hz frames.
const MOVE_SPEED := 300.0 # Horizontal pixels per second.
const ATTACK_MOVE_SPEED := 150.0 # Movement while attacking on the ground.
const BLOCK_MOVE_SPEED := 112.5 # Movement while guarding.
const ATTACK_SPEED := 1.25 # Attack timeline multiplier; 25% faster.
const ATTACK_INPUT_WINDOW := 0.75 # Mash presses survive startup and recovery.
const AIR_SPEED := 262.5 # Horizontal control while jumping.
const JUMP_SPEED := 620.0 # Positive magnitude; applied upward as negative Y.
const GRAVITY := 1800.0 # Downward pixels per second squared.
const MAX_HEALTH := 100
const ROUND_SECONDS := 60
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
const HIT_PUSH := 180.0 # Default travel distance on an unblocked hit, pixels.
const HIT_STUN_SECONDS := 0.4 # Minimum unblocked stun; attacks can specify longer.
const KNOCKBACK_SECONDS := 0.3 # Travel completes before the stun wears off.
const HIT_JUMP_SPEED := 260.0 # Default upward hit launch, pixels per second.
const BLOCK_PUSH := 8.0
const PARRY_PUSH := 120.0 # Attacker recoil distance after a front block.
const PARRY_STUN_SECONDS := 0.4
const AI_APPROACH_DISTANCE := 105.0
const AI_ATTACK_DISTANCE := 145.0
const ATTACKS := [
	{"startup": 6, "active": 4, "recovery": 13, "damage": 8, "stun": 18, "reach": 64.0},
	{"startup": 7, "active": 4, "recovery": 14, "damage": 10, "stun": 21, "reach": 72.0},
	{"startup": 10, "active": 5, "recovery": 22, "damage": 16, "stun": 24, "reach": 90.0}
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

## Difficulty changes decision cadence, movement, and guard reaction (not damage).
const AI_DIFFICULTIES := [
	{"name": "Easy", "interval": 0.85, "speed": 0.8, "reaction": 10.0, "guard": 0.2},
	{"name": "Normal", "interval": 0.6, "speed": 1.0, "reaction": 4.0, "guard": 0.65},
	{"name": "Hard", "interval": 0.25, "speed": 1.1, "reaction": 1.0, "guard": 0.95},
]

## Character and weapon choices from the original Scribble pack.
const CHARACTERS := [
	{"name": "Round Green", "body": "res://assets/scribble/character_roundGreen.png", "hand": "res://assets/scribble/character_handGreen.png", "color": Color("32b982")},
	{"name": "Round Purple", "body": "res://assets/scribble/character_roundPurple.png", "hand": "res://assets/scribble/character_handPurple.png", "color": Color("9464df")},
	{"name": "Round Red", "body": "res://assets/scribble/character_roundRed.png", "hand": "res://assets/scribble/character_handRed.png", "color": Color("ed5962")},
	{"name": "Round Yellow", "body": "res://assets/scribble/character_roundYellow.png", "hand": "res://assets/scribble/character_handYellow.png", "color": Color("e3ad27")},
	{"name": "Square Green", "body": "res://assets/scribble/character_squareGreen.png", "hand": "res://assets/scribble/character_handGreen.png", "color": Color("32b982")},
	{"name": "Square Purple", "body": "res://assets/scribble/character_squarePurple.png", "hand": "res://assets/scribble/character_handPurple.png", "color": Color("9464df")},
	{"name": "Square Red", "body": "res://assets/scribble/character_squareRed.png", "hand": "res://assets/scribble/character_handRed.png", "color": Color("ed5962")},
	{"name": "Square Yellow", "body": "res://assets/scribble/character_squareYellow.png", "hand": "res://assets/scribble/character_handYellow.png", "color": Color("e3ad27")},
]
const WEAPONS := [
	{"name": "Sword", "texture": "res://assets/scribble/item_sword.png"},
	{"name": "Spear", "texture": "res://assets/scribble/item_spear.png"},
	{"name": "Rod", "texture": "res://assets/scribble/item_rod.png"},
	{"name": "Pencil", "texture": "res://assets/scribble/item_pencil.png"},
]
