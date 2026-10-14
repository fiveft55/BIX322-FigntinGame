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
| HIT_PUSH / BLOCK_PUSH | Default unblocked travel distance / instant guarded shove, pixels |
| HIT_JUMP_SPEED | Default upward launch speed on an unblocked hit, pixels per second |
| AI_APPROACH_DISTANCE / AI_ATTACK_DISTANCE | Horizontal approach/attack thresholds, pixels |
| AI_ATTACK_INTERVAL | Seconds between AI attack decisions |
| Scene Player1/Player2 positions | Starting X coordinates, edited in arena.tscn |
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

_ready() sets 60 Hz physics, binds keys, references scene fighters, captures spawn positions, assigns opponents, builds HUD, and restarts. bind() replaces an action's runtime events with its configured physical key. create_hud() builds labels/health bars. restart() restores both fighters. _physics_process() handles match controls, ticks fighters, separates bodies, collects both hits before damage (allowing trades), handles KO, and updates HUD. Scenery nodes in arena.tscn provide the background and floor.

fighters owns both fighters, info is the status label, bars holds health bars, and round_over tracks the match outcome. Change Body and Hand Sprite2D textures in the fighter scenes for character colors and use_ai initialization for default local play. UI positions/fonts are in create_hud(). For a different viewport, update project.godot, settings bounds/spawns, and arena UI/background coordinates together. Keep physics at 60 Hz unless intentionally changing frame-based combat timing.

### Other files

- scenes/arena.tscn: main Node2D and its arena script; fighter instances and scenery are scene-authored; UI is created dynamically.
- project.godot: game name, main scene, viewport/stretch, renderer, background color.
- .gitignore: excludes generated .godot import cache. .gd.uid files identify scripts and belong in version control.
- tests/combat_test.gd: queue expiration/consumption, attack phases, damage/stun, once-per-strike hits, combo, directional guard.
- tests/arena_test.gd: AI approach/damage, KO freeze, restart.
- tests/jump_test.gd: real jump/movement actions, steering, no double jump, landing, vertical dodge, airborne stun, restart momentum reset.

Tests extend SceneTree, schedule run(), and exit nonzero on failure. Run the README commands after changing code. Headless tests validate mechanics; desktop playtesting evaluates appearance and feel.

## Simultaneous inputs and attack mashing

Input events are collected individually in `Fighter._input()`, including presses arriving between physics ticks. Keyboard auto-repeat is ignored. Hold movement while attacking or blocking; attack movement uses `ATTACK_MOVE_SPEED` and guard movement uses `BLOCK_MOVE_SPEED`. Jump + attack + movement can execute together, and airborne attacks use air steering. Attack takes priority over guard: pressing attack while holding guard starts a strike, and guard resumes after recovery. You cannot guard an attack while striking or airborne. Left + right cancel to zero horizontal input.

Attack presses remain queued for `ATTACK_INPUT_WINDOW` (0.75 seconds), while jump presses expire after `INPUT_WINDOW` (0.22 seconds). Rapid taps can queue successive combo strikes without timing every cancel window. Each tap is consumed once; enough extra taps can start another chain after the final strike if they have not expired. Queue capacity remains bounded; hits, restart, and AI toggles clear queued commands. Holding attack is not auto-fire. The keyboard hardware must support the chosen simultaneous keys; software cannot recover keys suppressed by keyboard ghosting.

## Scene-authored artwork

All texture references and placement now live in arena.tscn and fighter_green/purple.tscn. fighter_visual.gd references Sprite2D children, captures their scene transforms in _ready(), and applies simulation-driven pose offsets in update_pose(). SwordGrip pivots the sword around the hand. fighter.tick() refreshes this presentation without changing collision timing. arena.gd uses existing Player1/Player2 scene instances and captures scene spawn positions. ArenaVisual was removed; scenery no longer requires a script. See SCENE_GUIDE.md for the hierarchy and editing instructions.

## Hit reaction movement

Fighter exposes hit_push_distance, hit_jump_speed, and hit_stun_seconds as Inspector properties. receive_hit() launches upward and stores signed knockback_remaining and knockback_speed. The HIT_STUN branch of tick() moves that distance over KNOCKBACK_SECONDS (capped to the stun duration), while existing gravity integrates the hop. Direction is away from the attacker's position; walls clamp travel. Guard keeps a small immediate shove instead. reset_fighter() clears remaining displacement and speed. tests/knockback_test.gd checks editable values, both directions, landing, guard, walls, and restart.

HIT_STUN_SECONDS sets the default minimum unblocked stun (0.4 seconds); KNOCKBACK_SECONDS controls travel time (0.3 seconds). The effective hit stun is the larger of the per-character minimum converted to frames and the attack dictionary stun value. Default hit travel is 180 pixels. After travel finishes, HIT_STUN still ignores actions until the timer expires. Wall limits and repeat hits still apply.

## Shield reactions

RearHand/Shield is scene-authored. Fighter.guard_hit marks guarded HIT_STUN, resets on state transitions, and lets presentation distinguish guard recoil from full damage. FighterVisual.update_pose() blends the hand to guard_hand_offset over guard_raise_frames, applies guard_recoil_offset during guard stun, and restores the authored resting pose afterward. These pose settings are exported on Visuals. The shield stays visible at rest; gameplay protection still depends on BLOCKING and facing.

## Shield size and block parries

Shield scale is now reduced by 20% (80% of its original size) and its Z Index is 5 so it draws over the sword. Edit RearHand/Shield in either fighter scene to adjust scale or layering. Every successful front-facing block acts as a parry: it cancels the attack, applies no damage to the attacker, and pushes the attacker backward while stunning them for 0.4 seconds. Rear hits do not parry. Guard chip damage and the defender's brief guard stun still apply.

Select the Fighter root to edit **Parry Push Distance** (default 120 pixels, on the attacking character). `PARRY_STUN_SECONDS` in game_settings.gd controls parry recovery (default 0.4). `HIT_STUN_SECONDS` and the Fighter's **Hit Stun Seconds** now default to 0.4 seconds for unblocked hits. Attack data may specify longer hit stun. Arena walls limit push distance.

## Match clock and results

arena.gd.restart() resets the whole match and calls start_round(). start_round() restores fighters and initializes round_ticks_remaining to ROUND_SECONDS × 60. Each live physics tick subtracts one; stopped matches do not tick combat. finish_round() freezes both fighters, removes hitboxes, determines the winner by remaining health (equal is a draw), and displays match_overlay.tscn. update_match_hud() formats the clock and updates health bars. Victory/Rematch.pressed connects to restart(); Victory/Quit.pressed quits the tree. tests/match_test.gd runs a full timer, checks timeout/KO/draw, combat freezing, and button-driven rematch. No best-of-three scoring is implemented.

update_countdown() advances the 180-tick pre-fight sequence and updates text opacity. start_round() disables fighters and resets it; the final countdown tick enables fighters and shows FIGHT!. fight_fade_ticks then fades the label over 30 live-combat ticks. Match time is decremented only after the numeric countdown completes. tests/match_test.gd verifies numbers, fade, frozen time/positions, exact start, and disappearance.

## Audio events

Fighter.combat_sound is a custom signal emitted at actual sword active frames, jump launch, and hit/guard resolution. Arena connects it to MatchAudio.on_combat_sound. MatchAudio owns looping music, a sequential announcer queue advanced by AudioStreamPlayer.finished, and an eight-player effects pool. Source streams and volumes live in match_audio.tscn; independent Music/Voice/SFX buses live in default_bus_layout.tres. See AUDIO_GUIDE.md for every event mapping, controls, and test coverage.
