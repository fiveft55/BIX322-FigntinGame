# Scribble Fighters — Godot fighting game prototype

A self-contained Godot 4.6 project demonstrating finite state machines, frame-timed combat collision, and buffered combo input. Graphics use the included Kenney Scribble Platformer assets (CC0), with procedural poses synchronized to combat frames. No external downloads or plugins are required.

## Run

Import `project.godot` in Godot 4.6 and press **F6** on the arena scene or **F5** to play the project. Alternatively run `godot --path .` from this directory on a machine with a display.

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Move | A / D | Left / Right |
| Jump | W | Up |
| Attack / combo | F | K |
| Hold guard | G | L |

Player 2 starts as an AI opponent. **Tab** toggles AI/local play, **H** toggles collision visualization, and **R** restarts. Close the window to exit. Approach your opponent, then press attack repeatedly with short pauses to chain three strikes. An input entered during late recovery is retained until the cancel window opens. Guard protects the front and applies reduced damage and stun.

## Architecture for your project report

- `scripts/fighter.gd`: explicit `IDLE`, `WALKING`, `ATTACKING`, `HIT_STUN`, `BLOCKING`, and `JUMPING` states. `change_state()` centralizes transitions and destroys attack hitboxes when interrupted. Idle/walking/blocking can start an attack; attacks finish or chain into the next strike; incoming hits interrupt with timed stun. Block stun uses the same stun state with a shorter duration.
- `scripts/input_buffer.gd`: a bounded queue of timestamped commands, expiring after 220 ms for jump and 750 ms for attack. Consumption removes a command exactly once. Up to eight presses are retained; hits clear pending commands. This tolerates early presses without indefinite delayed attacks.
- Attacks use a fixed 60 Hz simulation timeline. Startup has no hitbox; active frames instantiate an `Area2D` with a separate rectangle; recovery destroys it. Persistent hurtboxes are separate `Area2D` nodes. Combat uses immediate rectangle intersection with identical dimensions, avoiding stale overlap lists when Godot defers physics updates. A per-attack victim list prevents repeated damage across active frames.
- `scripts/arena.gd`: input mapping, both fighters' simulation, body separation, simultaneous hit collection, health UI, round outcome, and restart. Both attacks are collected before damage is applied so trades can occur.

| Strike | Startup frames | Active frames | Recovery frames | Damage | Hit stun frames |
| --- | --- | --- | --- | --- | --- |
| 1 | 6 | 4 | 13 | 8 | 18 |
| 2 | 7 | 4 | 14 | 10 | 21 |
| 3 | 10 | 5 | 22 | 16 | 27 |

The final six recovery frames of strikes 1 and 2 allow a buffered attack to cancel into the next strike. These are simulation frames, with procedural attack poses driven by the same timeline; there are no imported sprite animation frames. This demo has one ground attack chain, local play, and a simple rule-based AI. It does not implement networking, audio, or a full competitive fighting-game ruleset.

## Validation

Run from the project directory:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/combat_test.gd
godot --headless --path . --script tests/arena_test.gd
godot --headless --path . --script tests/jump_test.gd
godot --headless --path . --script tests/assets_test.gd
godot --headless --path . --script tests/knockback_test.gd
godot --headless --path . --quit-after 180
```

The combat test checks input expiration and single consumption, startup/active/recovery hitbox timing, damage, stun, single-hit protection, buffered combo cancellation, and front/rear blocking. The last command smoke-tests the main scene. Interactive controls and appearance still need a visual playtest on a desktop.

In the cloud sandbox, set writable runtime directories before these commands:

```sh
export XDG_DATA_HOME=/workspace/godot-runtime/data
export XDG_CONFIG_HOME=/workspace/godot-runtime/config
export XDG_CACHE_HOME=/workspace/godot-runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
```

For a Bachelor's submission, supplement the prototype with your own design rationale, FSM diagram, frame-data experiments, test results, evaluation, and disclosure of AI assistance according to your institution's rules. This project is a technical foundation, not a guarantee of an academic grade.

## Customization

Edit `scripts/game_settings.gd` for movement keys, speed, gravity, jump height, health, attack data, and buffering. See [CODE_GUIDE.md](CODE_GUIDE.md) for every script and function, variable units, examples, and jump rules. W/Up jumps; steer in the air with movement keys. Attacks work on the ground and in the air; blocking is ground-only.

## Simultaneous inputs and attack mashing

Input events are collected individually in `Fighter._input()`, including presses arriving between physics ticks. Keyboard auto-repeat is ignored. Hold movement while attacking or blocking; attack movement uses `ATTACK_MOVE_SPEED` and guard movement uses `BLOCK_MOVE_SPEED`. Jump + attack + movement can execute together, and airborne attacks use air steering. Attack takes priority over guard: pressing attack while holding guard starts a strike, and guard resumes after recovery. You cannot guard an attack while striking or airborne. Left + right cancel to zero horizontal input.

Attack presses remain queued for `ATTACK_INPUT_WINDOW` (0.75 seconds), while jump presses expire after `INPUT_WINDOW` (0.22 seconds). Rapid taps can queue successive combo strikes without timing every cancel window. Each tap is consumed once; enough extra taps can start another chain after the final strike if they have not expired. Queue capacity remains bounded; hits, restart, and AI toggles clear queued commands. Holding attack is not auto-fire. The keyboard hardware must support the chosen simultaneous keys; software cannot recover keys suppressed by keyboard ghosting.

## Included artwork

The uploaded Kenney Scribble Platformer pack provides green/purple fighters, hands, shields, punch effects, trees, clouds, and ground tiles. See [ASSET_GUIDE.md](ASSET_GUIDE.md) for file mappings and replacement instructions. The pack has static PNGs, not animation sheets or audio; poses are animated in code. Original CC0 license: [assets/scribble/License.txt](assets/scribble/License.txt).

## Edit artwork in the scene editor

Open scenes/arena.tscn for organized scenery and fighter instances. Open scenes/fighter_green.tscn or scenes/fighter_purple.tscn to edit body, hands, swords, shields, and effects directly in the Inspector. Both fighters now swing swords using the timed attack hitboxes. See [SCENE_GUIDE.md](SCENE_GUIDE.md) for step-by-step placement and replacement instructions.

Unblocked hits now launch fighters upward and backward. Select the Fighter root in either fighter scene to edit **Hit Push Distance** (pixels) and **Hit Jump Speed** (pixels/second). See SCENE_GUIDE.md for tuning and scene overrides.

Default unblocked hits now push 180 pixels over 0.3 seconds and stun for 0.5 seconds. **Hit Stun Seconds** joins the editable Fighter Inspector settings. Attack frame-data stun values are lower bounds; the per-character 30-frame default minimum takes precedence. Blocking keeps its short guard stun.

Collision outlines are hidden by default. Press H to toggle green hurtboxes and red attack hitboxes for debugging.

Both fighters hold shields in their free hands. Guard raises that hand; a blocked hit briefly recoils it. Tune the guard hand pose on the Visuals node in either fighter scene.

## Shield size and block parries

Shield scale is now reduced by 65% (35% of the previous size) and its Z Index is 5 so it draws over the sword. Edit RearHand/Shield in either fighter scene to adjust scale or layering. Every successful front-facing block acts as a parry: it cancels the attack, applies no damage to the attacker, and pushes the attacker backward while stunning them for 0.5 seconds. Rear hits do not parry. Guard chip damage and the defender's brief guard stun still apply.

Select the Fighter root to edit **Parry Push Distance** (default 120 pixels, on the attacking character). `PARRY_STUN_SECONDS` in game_settings.gd controls parry recovery (default 0.5). `HIT_STUN_SECONDS` and the Fighter's **Hit Stun Seconds** now default to 0.5 seconds for unblocked hits. Attack data may specify longer hit stun. Arena walls limit push distance.
