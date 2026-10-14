# Code and customization guide

## Change keys and gameplay variables

Edit **scripts/game_settings.gd**, save, then restart the game. Constants affect both fighters. The on-screen key labels use the same settings automatically. These are code constants, not Inspector fields.

| Setting | Purpose and unit |
| --- | --- |
| ATTACK_MOVE_SPEED / BLOCK_MOVE_SPEED | Ground attack/guard movement speed, pixels per second |
| MOVE_SPEED / AIR_SPEED | Ground/air horizontal speed, pixels per second |
| JUMP_SPEED | Upward launch magnitude, pixels per second; larger means higher |
| GRAVITY | Downward acceleration, pixels per second squared |
| MAX_HEALTH | Starting health and health-bar maximum |
| FLOOR_Y | Foot height when grounded; positive Y goes downward |
| LEFT_BOUND / RIGHT_BOUND | Limits for fighter foot X positions |
| BODY_WIDTH | Body separation and attack origin offset |
| HURTBOX_SIZE / HURTBOX_CENTER | Receiving rectangle dimensions/offset relative to feet |
| HITBOX_HEIGHT / HITBOX_Y | Attack rectangle height/vertical center relative to feet |
| INPUT_WINDOW | Jump queue expiration in seconds |
| ATTACK_INPUT_WINDOW | Attack queue expiration in seconds |
| MAX_BUFFER_COMMANDS | Capacity; oldest command is dropped when full |
| COMBO_CANCEL_FRAMES | Final recovery frames permitting the next strike |
| BLOCK_DAMAGE / BLOCK_STUN_FRAMES | Guard chip damage and stun duration |
| HIT_PUSH / BLOCK_PUSH | Immediate horizontal hit displacement, pixels |
| AI_APPROACH_DISTANCE / AI_ATTACK_DISTANCE | Horizontal approach/attack thresholds, pixels |
| AI_ATTACK_INTERVAL | Seconds between AI attack decisions |
| SPAWN_POSITIONS | Starting X coordinates for both players |
| ATTACKS | Ordered dictionaries defining combo strikes |
| KEYS | Action names mapped to physical keyboard keys |

To jump higher and float longer, try JUMP_SPEED = 700.0 and GRAVITY = 1600.0. Approximate height = speed²/(2 × gravity), airtime = 2 × speed/gravity. Defaults give about 107 pixels and 0.69 seconds, with small discrete-step differences. Keep speed, gravity, dimensions, and capacity positive.

### Change movement keys

In the KEYS dictionary, replace the constant for the desired action:

```gdscript
"p1_left": KEY_A,
"p1_right": KEY_D,
"p1_jump": KEY_SPACE, # Changes player 1 jump from W to Space.
```

Player 2 uses p2_left, p2_right, and p2_jump. Other actions are p1_attack, p1_block, p2_attack, p2_block, restart, boxes, and ai. Constants include KEY_W, KEY_UP, KEY_SHIFT, and KEY_SPACE. Avoid duplicate keys. Bindings use physical keyboard positions. Settings overwrite runtime Input Map bindings on startup; editing only Project Settings → Input Map will not change these defaults. Adding an action also requires implementing its behavior. Tab switches player 2 from AI to local controls.

### Change attacks

Each ATTACKS dictionary has startup, active, recovery, damage, stun, and reach. Durations are integer frames at 60 Hz; reach is pixels. The default first strike becomes active on frame 6 and loses its hitbox on frame 10. Keep startup/active at least 1, recovery nonnegative, and COMBO_CANCEL_FRAMES no greater than recovery. Append a dictionary to extend the combo; code uses array length. Tests assert default timing/damage, so deliberately update expected results when tuning defaults.

## Jump rules

W/Up queues a jump. Idle, walking, or blocking consumes it; jump and attack execute together when both are queued. A recent jump press in attack recovery can execute afterward if it has not expired. JUMPING allows air steering and attacks, but no double jump or airborne guard. Holding jump does not repeat; a fresh press shortly before landing may trigger another jump after landing. Jump plus attack launches an aerial strike immediately; its hitbox follows the fighter in the air.

Gravity continues during airborne hit stun. Landing clamps feet to FLOOR_Y and clears vertical velocity; jumping becomes idle, but stun must finish separately. Stun finishing in the air returns to jumping. Hurtboxes follow vertical position, so high jumps can avoid ground attacks. Body separation only applies where hurtboxes overlap, allowing jump-over movement. The AI stays on the ground. Restart clears momentum.

This project uses an explicit mathematical floor plane, not platform collisions. CharacterBody2D is moved directly; is_grounded() replaces is_on_floor(). Adding platforms requires a deliberate collision/move_and_slide() redesign.

## File and function reference

### scripts/game_settings.gd

GameSettings is a shared RefCounted class containing tuning constants. key_label(action) converts configured keys into HUD text. It has no process or saved state.

### scripts/input_buffer.gd

FightInputBuffer owns commands (command/time dictionaries) and a simulation clock. advance(delta) advances time and expires stale commands. push(command) appends a timestamped press and caps capacity. consume(command) removes the oldest matching command exactly once and returns success. clear() removes pending presses on hit, restart, and AI toggle. This is a command queue rather than a special-move directional recognizer.

### scripts/fighter.gd

| Function | Responsibility |
| --- | --- |
| _input | Capture individual attack/jump presses; ignore keyboard auto-repeat |
| _ready | Create persistent hurtbox; arena owns scheduling |
| make_area | Build Area2D and rectangle collision shape with specified layers |
| change_state | Reset state frame and clean up a leaving attack hitbox |
| start_attack | Select combo index, enter attack, clear already-hit victims |
| remove_hitbox | Detach/free active attack collision node |
| tick | Read input/AI, advance FSM, integrate horizontal movement and gravity |
| is_grounded | Test foot position and non-upward velocity against floor |
| attack_rectangle | Compute world attack rectangle mirrored by facing |
| hurt_rectangle | Compute world receiving rectangle |
| resolve_attack | Resolve one attack for isolated tests; arena batches match hits |
| receive_hit | Apply guard/damage/stun/push and clear inputs |
| reset_fighter | Reset health, state, position, velocity, buffer, AI timer |
| _draw | Draw optional collision visualization; FighterVisual draws artwork |

Runtime fields: state/state_frame track the FSM; health tracks damage; facing is ±1; combo selects attack data; stun_remaining counts stun frames. Inherited velocity is pixels/second. player_index selects action names; opponent references the other fighter. buffer stores commands; hurtbox/hitbox are Area2D nodes; victims stores already-hit IDs. enabled freezes combat after KO. use_ai/ai_timer drive decisions. debug_boxes controls collision overlays. Artwork paths are configured in GameSettings. Tune settings rather than runtime fields.

AI guard timing remains in tick(): fmod(ai_timer, 1.5) < 0.65. Edit this expression for different simple guard behavior. Drawing coordinates in FighterVisual._draw() control art independently of collision size; adjust the art if you resize hurtboxes. Immediate rectangle checks use the same dimensions as collision nodes to avoid deferred physics overlap updates.

### scripts/arena.gd

_ready() sets 60 Hz physics, binds keys, creates fighters/opponent references, enables default AI, builds HUD, and restarts. bind() replaces an action's runtime events with its configured physical key. create_hud() builds labels/health bars. restart() restores both fighters. _physics_process() handles match controls, ticks fighters, separates bodies, collects both hits before damage (allowing trades), handles KO, and updates HUD. ArenaVisual draws arena/grid/floor.

fighters owns both fighters, info is the status label, bars holds health bars, and round_over tracks the match outcome. Change CHARACTER_TEXTURES and HAND_TEXTURES in settings for character colors and use_ai initialization for default local play. UI positions/fonts are in create_hud(). For a different viewport, update project.godot, settings bounds/spawns, and arena UI/background coordinates together. Keep physics at 60 Hz unless intentionally changing frame-based combat timing.

### Other files

- scenes/arena.tscn: main Node2D and its arena script; fighters/UI are created dynamically.
- project.godot: game name, main scene, viewport/stretch, renderer, background color.
- .gitignore: excludes generated .godot import cache. .gd.uid files identify scripts and belong in version control.
- tests/combat_test.gd: queue expiration/consumption, attack phases, damage/stun, once-per-strike hits, combo, directional guard.
- tests/arena_test.gd: AI approach/damage, KO freeze, restart.
- tests/jump_test.gd: real jump/movement actions, steering, no double jump, landing, vertical dodge, airborne stun, restart momentum reset.

Tests extend SceneTree, schedule run(), and exit nonzero on failure. Run the README commands after changing code. Headless tests validate mechanics; desktop playtesting evaluates appearance and feel.

## Simultaneous inputs and attack mashing

Input events are collected individually in `Fighter._input()`, including presses arriving between physics ticks. Keyboard auto-repeat is ignored. Hold movement while attacking or blocking; attack movement uses `ATTACK_MOVE_SPEED` and guard movement uses `BLOCK_MOVE_SPEED`. Jump + attack + movement can execute together, and airborne attacks use air steering. Attack takes priority over guard: pressing attack while holding guard starts a strike, and guard resumes after recovery. You cannot guard an attack while striking or airborne. Left + right cancel to zero horizontal input.

Attack presses remain queued for `ATTACK_INPUT_WINDOW` (0.75 seconds), while jump presses expire after `INPUT_WINDOW` (0.22 seconds). Rapid taps can queue successive combo strikes without timing every cancel window. Each tap is consumed once; enough extra taps can start another chain after the final strike if they have not expired. Queue capacity remains bounded; hits, restart, and AI toggles clear queued commands. Holding attack is not auto-fire. The keyboard hardware must support the chosen simultaneous keys; software cannot recover keys suppressed by keyboard ghosting.

## Asset presentation scripts

`scripts/fighter_visual.gd` loads configured body/hand textures and shared shield/blast art in `_ready()`. Its `_draw()` reads the fighter state and frame counter for walking bob, jump lean, attack windup/extension/recovery, stun flash, and guarding. It mirrors artwork independently of collision. Fighter.tick() requests a visual redraw; presentation never applies damage or advances combat.

`scripts/arena_visual.gd` loads scenery textures in `_ready()`, uses `stamp()` to draw texture rectangles, and draws the notebook background and decorative scenery in `_draw()`. Tiles align with FLOOR_Y. Trees/castles are decoration, not platforms. See ASSET_GUIDE.md for asset paths and sizing.
