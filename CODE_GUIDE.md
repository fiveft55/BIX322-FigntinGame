# Code reference for this project

This guide describes the current implementation. Start with [README.md](README.md) to run the game, [SCENE_GUIDE.md](SCENE_GUIDE.md) to edit artwork, and [ARCHITECTURE.md](ARCHITECTURE.md) for system diagrams and signals.

## Shared tuning: `scripts/game_settings.gd`

`GameSettings` is a `RefCounted` class used for constants and catalogs, not a running node. Edit its constants and restart the game to apply changes.

| Setting | Default | Meaning |
| --- | --- | --- |
| `MOVE_SPEED` | 300 | Ground pixels/second |
| `AIR_SPEED` | 262.5 | Air steering pixels/second |
| `ATTACK_MOVE_SPEED` | 150 | Ground attack movement pixels/second |
| `BLOCK_MOVE_SPEED` | 112.5 | Guard movement pixels/second |
| `ATTACK_SPEED` | 1.25 | Attack-timeline advancement per physics tick |
| `JUMP_SPEED` | 620 | Upward launch magnitude, pixels/second |
| `GRAVITY` | 1800 | Downward acceleration, pixels/second² |
| `MAX_HEALTH` | 100 | Initial health and health-bar maximum |
| `ROUND_SECONDS` | 60 | Live match length |
| `FLOOR_Y` | 520 | Grounded foot Y coordinate |
| `LEFT_BOUND` / `RIGHT_BOUND` | 42 / 1110 | Fighter X limits |
| `BODY_WIDTH` | 44 | Separation distance and hitbox origin offset |
| `HURTBOX_SIZE` / `HURTBOX_CENTER` | (42,104) / (0,-54) | Receiving rectangle dimensions/offset from feet |
| `HITBOX_HEIGHT` / `HITBOX_Y` | 36 / -62 | Attack rectangle height/center relative to feet |
| `INPUT_WINDOW` | 0.22 | Jump command lifetime, seconds |
| `ATTACK_INPUT_WINDOW` | 0.75 | Attack command lifetime, seconds |
| `MAX_BUFFER_COMMANDS` | 8 | Queue capacity |
| `COMBO_CANCEL_FRAMES` | 6 | Final recovery timeline frames permitting the next strike |
| `BLOCK_DAMAGE` / `BLOCK_STUN_FRAMES` | 1 / 8 | Guard chip damage / defender stun |
| `HIT_PUSH` / `HIT_JUMP_SPEED` | 180 / 260 | Default hit travel distance / upward speed |
| `HIT_STUN_SECONDS` | 0.4 | Default minimum unblocked stun |
| `KNOCKBACK_SECONDS` | 0.3 | Horizontal travel duration |
| `BLOCK_PUSH` | 8 | Instant grounded shove on a guarded hit |
| `PARRY_PUSH` / `PARRY_STUN_SECONDS` | 120 / 0.4 | Attacker recoil distance / recovery |
| `AI_APPROACH_DISTANCE` / `AI_ATTACK_DISTANCE` | 105 / 145 | Horizontal AI decision thresholds |

`ATTACKS` contains ordered dictionaries with `startup`, `active`, `recovery`, `damage`, `stun`, and `reach`. Timings are base timeline frames; reach is pixels. The README has the full table. `AI_DIFFICULTIES` contains decision interval, movement multiplier, reaction threshold, and guard availability. `CHARACTERS`, `WEAPONS`, and `HATS` provide names, texture paths, and character colors. `key_label()` translates `KEYS` into readable menu/console labels.

Keep speeds, gravity, dimensions, and travel duration positive. Keep attack startup/active at least one frame and recovery nonnegative; the cancel window should not exceed recovery. Large attack-speed multipliers can cross both the active start and end in one physics tick, leaving no collision opportunity; the default 1.25 is tested. Changing the 60 Hz engine tick rate requires updating frame-based timers and formulas throughout the project.

### Keys

Change `KEYS`, for example `"p1_jump": KEY_SPACE`, to use Space instead of W. Bindings use physical key positions. Arena startup overwrites runtime Input Map events from this dictionary, so editing only Project Settings → Input Map is insufficient. Adding an action also requires implementing its behavior. Avoid duplicate keys and test keyboard rollover for simultaneous presses.

## Fighter: `scripts/fighter.gd`

| Function | Responsibility |
| --- | --- |
| `_ready()` | Create persistent hurtbox, apply saved textures/headgear, reference scene visuals |
| `make_area()` | Construct Area2D with rectangle shape and specified layer/mask |
| `change_state()` | Remove interrupted hitbox, print transition, reset frame counter/guard reaction |
| `start_attack()` | Enter attack, choose combo index, clear already-hit targets |
| `remove_hitbox()` | Detach/free active attack area |
| `_input()` | Capture attack/jump presses individually; ignore echo, disabled fighters, and AI input |
| `tick()` | Advance buffer, human/AI decisions, FSM, movement, gravity, and presentation |
| `is_grounded()` | Test foot height and non-upward velocity |
| `attack_rectangle()` / `hurt_rectangle()` | Calculate world rectangles matching collision shapes |
| `resolve_attack()` | Isolated attack resolution used by tests; arena batches real-match hits |
| `receive_hit()` | Apply guard/damage/stun, clear inputs, initiate push/hop or parry |
| `receive_parry()` | Cancel attacking fighter, apply recoil/stun without damage |
| `reset_fighter()` | Reset state, health, position, momentum, queue, and AI timer |
| `_draw()` | Optional green hurtbox/red attack overlays |

Inspector exports on the Fighter root are `player_index`, `use_ai`, `hit_push_distance`, `hit_jump_speed`, `hit_stun_seconds`, and `parry_push_distance`. Player index selects inputs and saved customization slots. Arena sets `use_ai` from the chosen mode; Tab may change it only in AI practice. Explicitly saved Inspector overrides take precedence over changed script default values.

Runtime fields include state/frame, health, facing (±1), combo index, stun ticks, guard-hit flag, remaining knockback/speed, inherited velocity, opponent reference, command buffer, collision nodes, hit-victim IDs, enabled flag, and AI timer. `state_frame` is fractional for attacks and advances by one for other states. `guard_hit` distinguishes a shield recoil from unblocked damage while both use HIT_STUN.

Jump + attack executes together when both commands are available. Attacks take priority over held guard. Air steering and aerial attacks are allowed; guard/double-jump are not. A fresh jump press near landing can survive until grounded; holding the key does not repeatedly jump. Gravity continues during airborne stun. Movement uses explicit positions and a mathematical floor, rather than `move_and_slide()` or platform collision.

## Input buffer: `scripts/input_buffer.gd`

`commands` stores command/time/window dictionaries; `clock` tracks simulation seconds. `advance(delta)` expires stale entries; `push()` appends a timestamped entry and drops the oldest at capacity; `consume()` removes the oldest matching entry once; `clear()` drops all entries. Attack and jump have separate lifetimes. This recognizes queued actions rather than directional special-move sequences.

## Fighter poses: `scripts/fighter_visual.gd`

`_ready()` caches scene-authored body/hand/effect positions and body/grip rotations. `update_pose()` adds walking bob, jumping lean, sword windup/extension/recovery, hit shake/tint, and shield-hand movement. It mirrors the Rig to face the opponent; collision mirroring is handled independently. Child hats follow Body and shields follow RearHand. During a blocked hit the shield stays raised and recoils; it is always held at rest.

Exported pose controls are `guard_hand_offset` (48,-18), `guard_raise_frames` (6), and `guard_recoil_offset` (-10,4). This script never applies damage, owns attack timing, or loads texture choices. Fighter startup supplies textures, and gameplay supplies state/frame information.

## Match coordinator: `scripts/arena.gd`

| Function | Responsibility |
| --- | --- |
| `_ready()` | Bind keys, reference scene fighters, capture mode/spawns, connect audio/UI, restart |
| `bind()` | Replace an action's physical key mapping |
| `create_hud()` | Build title/health bars and print console controls |
| `restart()` / `start_round()` | Clear cinematic, restore fighters, initialize clock and countdown |
| `finish_round()` | Stop combat once; begin knockout cinematic or show timeout result |
| `show_result()` | Determine health-based winner, play result audio, display result panel |
| `launch_equipment()` | Detach weapon, shield, and optional headgear into flying props |
| `spawn_flying_equipment()` | Copy a source sprite world transform and assign launch velocity/spin |
| `tick_cinematic()` | Move victim/equipment with scaled delta; measure delay with normal delta |
| `clear_cinematic()` | Remove loose props and restore attached equipment |
| `update_match_hud()` | Refresh timer and health bars |
| `update_countdown()` | Advance numbered fade/voice checkpoints and enable fighters at FIGHT |
| `_physics_process()` | Gate shortcuts, update match phase, simulate fighters, separate bodies, resolve hits |
| `return_to_menu()` | Disable fighters, stop battle audio, change scene |
| `_unhandled_key_input()` | Handle Escape menu return |

`round_over` stops new combat; `cinematic_active` permits only the knockout presentation; `match_over` becomes true when results are visible. `ai_practice_mode` records the initial match selection and does not change with Tab. Clock/countdown/fight-fade are integer tick counters. `flying_equipment` stores sprite/velocity/spin dictionaries. Arena exports cinematic duration (1.4) and slow factor (0.25).

Health bars and title are generated in code; scenery, fighters, overlays, and audio assignments are scene-authored. Both attacks are collected before applying damage so trades can occur. Clouds run their own physics callbacks; they do not slow down with the cinematic.

## Cloud movement: `scripts/cloud_drift.gd`

`_physics_process(delta)` moves a Sprite2D by exported `drift_speed` and wraps after its full visible width leaves viewport bounds. Arena scene defaults are +10 and -8 pixels/second. Texture width and scene scale determine wrapping margins.

## Menus: `scripts/main_menu.gd`

`_ready()` connects widgets, starts looping menu music, restores selections, populates catalogs, builds control text, and opens Home. `show_page()` selects a page/focus target. `select_ai_mode()`, `reset_home()`, and `set_home_buttons()` switch between the original three buttons and Play/Difficulty/Main Menu in the same card.

`set_difficulty()`, `set_volume()`, and `update_volume_label()` update/synchronize saved settings and audio buses. `configure_characters()` creates dropdown entries; `choose_character()`, `choose_weapon()`, and `choose_hat()` save choices; `update_preview()` applies art/palette. `update_controls()` uses configured keys. `start_game()` records local/AI mode, disables navigation, plays the start cue, waits 0.5 seconds, and changes to Arena. Escape navigates back; `_exit_tree()` stops menu audio.

## Persistent options: `scripts/preferences.gd`

Preferences is a project autoload. `_ready()` calls `load_settings()` and `apply_volumes()`. Load/save use ConfigFile at `settings_path`, defaulting to `user://settings.cfg`; tests use an isolated path. `save_settings()` returns an Error. Loaded indices and numeric volumes are clamped; missing/unreadable files leave defaults. Unexpected incompatible value types are not fully validated.

Persisted fields are difficulty, music/effects/voice volumes, and two-element character/weapon/hat arrays. `local_mode` is runtime-only. `apply_volumes()` maps normalized linear gains to Music/SFX/Voice dB values and mutes zero gain.

## Audio: `scripts/match_audio.gd`

`_ready()` duplicates/enables looping music, creates eight effect players, and connects announcer `finished`. `reset_match()` stops all sound and clears queue; `_exit_tree()` releases streams. `say()` replaces countdown voice, `begin_battle()` starts music/FIGHT, `play_next_voice()` advances the result queue, `play_effect()` chooses an idle effect player (or replaces the first if all are busy), and `on_combat_sound()` routes fighter events. `play_knockout()` uses a dedicated hurt player. `finish_match()` stops music/effects and queues timeout/player/winner/draw clips while leaving the knockout cue able to finish. See [AUDIO_GUIDE.md](AUDIO_GUIDE.md) for exact resources.

The final-blow cinematic detaches the weapon and shield as well as optional headgear. spawn_flying_equipment() preserves each source sprite's global transform, hides the original, and assigns an independent arc/spin. Weapon launch is 260 horizontally / 360 upward with spin 8; shield launch is 160 horizontally / 300 upward with opposite spin 6; headgear uses 220 / 420 with spin 5. These are pixels/second and radians/second, scaled by cinematic delta. All share prop gravity 900. Fighter.equipment_detached prevents pose updates from showing hand equipment again; reset/clear restores it. Loose props are cosmetic and have no collision/damage.
