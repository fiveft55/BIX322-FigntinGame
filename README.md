# Scribble Fighters

A local 2D fighting game built with **Godot 4.6 and GDScript**, using Kenney's hand-drawn Scribble Platformer artwork. Play against a configurable AI or a second player on the same keyboard, customize both fighters, and compete in a single 60-second match.

The project demonstrates three core technical systems: an explicit finite state machine, frame-timed hitbox/hurtbox detection, and buffered input for responsive combos. Artwork, menu layouts, and audio are included in the repository; no plugins or external downloads are required to play.

## Quick start

1. Install [Godot 4.6](https://godotengine.org/download/) — the standard build is sufficient; .NET is not required.
2. Clone the repository:

   ```sh
   git clone https://github.com/fiveft55/BIX322-FigntinGame.git
   cd BIX322-FigntinGame
   ```

3. In Godot's Project Manager, choose **Import** and select `project.godot`.
4. Let Godot import the assets, then press **F5** to open the main menu.

From a terminal with Godot on your PATH and a graphical display:

```sh
godot --path .
```

The viewport is 1152 × 648 with canvas stretching. The compatibility renderer is used. Development checks have been run with Godot **4.6.3**.

## Playing a match

- **Player vs AI:** select this option to reveal the difficulty dropdown, choose Easy, Normal, or Hard, then press **Play**.
- **Player vs Player:** starts local two-player play.
- **Customize:** choose each player's body/color, weapon, and hat before playing.
- **Settings cog:** adjust music, effects, and voice volume; open **Controls** from this page.
- **Cross icon:** quit the game from the main menu.

Each match begins with a fading, voiced **3 → 2 → 1 → FIGHT!** countdown. Fighters and the match clock stay paused during the three-second count. A knockout ends the match early. At timeout, the player with more health wins; equal health is a draw. There is no best-of-three scoring.

The result screen shows the winner/draw and **Knockout** or **Time Up**, without health numbers. **Play Again** starts a fresh countdown; **Main Menu** returns to the menu. Press **Esc** during a fight to return to the menu.

### Controls

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Move left/right | A / D | Left / Right |
| Jump | W | Up |
| Melee attack / combo | F | K |
| Hold shield guard | G | L |

Hold movement while attacking or guarding. Movement, jump, and attack can combine into an aerial strike. Rapid attack taps can queue the three-strike combo; holding attack does not auto-fire. There is no double jump or airborne guard. Opposite movement directions cancel each other.

These shortcuts are available **only in matches launched as Player vs AI**:

| Key | Action |
| --- | --- |
| R | Restart the match |
| H | Toggle collision visualization |
| Tab | Toggle the practice opponent between AI and manual control |

Local PvP ignores these shortcuts. AI practice retains them even when Tab temporarily switches its opponent to manual control. Gameplay state transitions and control information print in Godot's **Output** panel or the launch terminal, rather than on-screen diagnostic labels.

### Combat and hit reactions

- Attacks have startup, active, and recovery phases. Damage occurs only during active hitbox frames.
- Each attack can damage a target once, even if its active hitbox overlaps for multiple ticks.
- A successful front-facing shield block acts as a **parry**: it cancels the attack and pushes the attacker back. Rear hits bypass guard.
- Unblocked hits launch the victim upward and backward. Defaults are **180 pixels** of travel over **0.3 seconds**, with **0.4 seconds** of hit stun.
- Parry defaults are **120 pixels** of attacker recoil and **0.4 seconds** of stun. Guard still applies chip damage and a shorter defender guard stun.
- Walls limit actual knockback distance. A new hit replaces the previous knockback and restarts stun.

## Customization and settings

Both players can select eight body/color combinations: round or square characters in green, purple, red, and yellow. Health bars match the selected colors. Hats include No Hat, Cap, Top Hat, Helmet, and Modern Helmet.

Weapons include Sword, Spear, Rod, and Pencil. These are **melee visual variants sharing the same attack rules and hitboxes**; they do not introduce projectile attacks or different weapon statistics. Hats are decorative.

Difficulty, character/weapon/hat selections, and audio volumes persist in `user://settings.cfg`. This is Godot's application-data directory, not a tracked repository file. Music, effects, and announcer voice have independent volume controls; zero mutes the corresponding bus.

### Where to edit things

| Change | Location |
| --- | --- |
| Keys, speeds, jump/gravity, health, round length, buffering, attack data | `scripts/game_settings.gd` |
| AI difficulty profiles and character/weapon/hat catalogs | `scripts/game_settings.gd` |
| Per-character knockback, hit launch, stun, and parry distance | Fighter root Inspector in `scenes/fighter_green.tscn` / `fighter_purple.tscn` |
| Shield-hand raise and recoil pose | Visuals Inspector in either fighter scene |
| Body, hand, weapon, shield, and hat placement | Sprite nodes in either fighter scene |
| Arena scenery and starting player X positions | `scenes/arena.tscn` |
| Main menu arrangement, title font, cog/cross icons | `scenes/main_menu.tscn` |
| Solid cards, button colors, keyboard focus styling | `scenes/menu_theme.tres` |
| Countdown and translucent result panel | `scenes/match_overlay.tscn` |
| Battle sounds, announcer clips, base mix volumes | `scenes/match_audio.tscn` |
| Independent audio buses | `default_bus_layout.tres` |

Saved menu selections override default fighter texture choices at runtime; scene-authored transforms remain editable. Keep the fighter node hierarchy intact because the pose script references those nodes. The ground is a mathematical floor plane: decorative tiles do not supply platform collisions.

## Technical architecture

| Component | Responsibility |
| --- | --- |
| `fighter.gd` | FSM, input capture, movement/jumping, attack phases, damage, guard/parry, knockback |
| `input_buffer.gd` | Bounded timestamped command queue with expiration and single consumption |
| `fighter_visual.gd` | Scene-authored sprite poses synchronized with combat state and attack frames |
| `arena.gd` | Fighter updates, body separation, simultaneous hit collection, timer/countdown/results |
| `match_audio.gd` | Looping music, overlapping effects, queued announcer playback |
| `main_menu.gd` | Navigation, difficulty, settings, customization previews, scene transitions |
| `preferences.gd` | Autoload for validated, persistent choices and audio bus gains |

The FSM has `IDLE`, `WALKING`, `JUMPING`, `ATTACKING`, `HIT_STUN`, and `BLOCKING` states. State transitions clean up interrupted hitboxes. Gravity continues during airborne hit stun, and landing clamps the fighter's feet to the floor.

Persistent hurtboxes and temporary attack hitboxes are separate `Area2D` rectangles. Combat resolves immediate world-rectangle intersections using the same dimensions as those collision nodes, avoiding delayed overlap queries after hitbox creation. The arena collects both attacks before applying damage, permitting simultaneous trades.

Human input events are captured individually, including multiple presses between physics ticks; keyboard auto-repeat is ignored. The queue holds up to eight commands. Jump commands expire after **220 ms**, attack commands after **750 ms**. Hits, restart, and AI toggles clear pending input.

Physics runs at **60 Hz**. `ATTACK_SPEED = 1.25` advances the attack timeline 25% faster than its base frame data. Threshold-crossing checks keep hitbox activation correct when a tick advances more than one attack frame. Sprite poses and sword audio follow the same timeline; stun, gravity, and match-clock timing are independent.

| Strike | Base startup | Base active | Base recovery | Damage | Base stun frames |
| --- | --- | --- | --- | --- | --- |
| 1 | 6 | 4 | 13 | 8 | 18 |
| 2 | 7 | 4 | 14 | 10 | 21 |
| 3 | 10 | 5 | 22 | 16 | 24 |

Startup/active/recovery values are attack-timeline frames, accelerated by `ATTACK_SPEED`; actual durations are quantized to physics ticks. The final six recovery frames permit combo chaining. Hit stun is the larger of the attack's base stun and the per-character minimum: by default **24 physics ticks / 0.4 seconds**.

AI is deterministic and rule-based. Difficulty changes movement speed, attack decision cadence, and guard reaction/availability; it does not change damage or health.

## Project layout

```text
assets/
  scribble/              Kenney textures, original sample, and license
  audio/                 Battle, menu, and voice files with license notes
  fonts/                 Bundled Google Font and SIL Open Font License
scenes/
  main_menu.tscn         Entry scene and menu pages
  arena.tscn             Editable scenery and fighter instances
  fighter_*.tscn         Editable fighter rigs
  match_overlay.tscn     Timer, countdown, and result screen
  match_audio.tscn       Sound assignments and players
  menu_theme.tres        Shared UI styles
scripts/                 Gameplay, presentation, menus, and preferences
tests/                   Nine headless regression suites
project.godot            Godot project configuration
```

## Testing

From the repository root, import resources before running the suites:

```sh
godot --headless --path . --editor --import --quit

for suite in combat arena jump assets knockback match audio menu cinematic; do
  godot --headless --path . --script "tests/${suite}_test.gd" || exit 1
done
```

| Suite | Coverage |
| --- | --- |
| Combat | Input expiration/consumption, hitbox phases, damage, combos, guard, simultaneous input, speeds |
| Arena | AI damage, KO freezing, restart |
| Jump | Launch/steering, no double jump, landing, aerial evasion/stun, reset |
| Assets | Texture loading, scene poses, sword timing, shield attachment/raise/recoil |
| Knockback | Travel, direction, walls, stun duration, guard/parry reactions |
| Match | Full timer, countdown/fade, timeout/KO/draw, result display, rematch |
| Audio | Countdown routing, music looping/start/stop, effects, voice ordering, cleanup |
| Menu | Navigation/layout, font fit, settings persistence, previews, selections, health colors, AI behavior, PvP shortcut restrictions |
| Cinematic | Cloud drift/wrap, final-hit slow motion, helmet flight, delayed results, restart cleanup |

All nine suites have passed in the cloud environment. Headless checks validate mechanics and configuration; they do not replace desktop playtesting for visual layout, controller feel, audio levels, or the music loop boundary.

For a restricted cloud sandbox, redirect Godot's writable runtime directories before running commands:

```sh
export XDG_DATA_HOME=/workspace/godot-runtime/data
export XDG_CONFIG_HOME=/workspace/godot-runtime/config
export XDG_CACHE_HOME=/workspace/godot-runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
```

## Detailed guides

- [Code guide](CODE_GUIDE.md): functions, variables, FSM behavior, and tuning.
- [Scene guide](SCENE_GUIDE.md): placing artwork, weapon pivots, shield poses, and collision alignment.
- [Menu guide](MENU_GUIDE.md): menu layout, AI profiles, customization, and saved preferences.
- [Audio guide](AUDIO_GUIDE.md): sound mappings, volumes, buses, and playback flow.
- [Asset guide](ASSET_GUIDE.md): original artwork and replacement instructions.

## Credits and licenses

- Project license: [CC0 1.0](LICENSE).
- **Kenney Scribble Platformer** artwork, including the sample background: [original CC0 license](assets/scribble/License.txt), by [Kenney](https://kenney.nl/).
- **Kenney Voiceover Pack: Fighter**: [original CC0 license](assets/audio/voice/License.txt).
- Uploaded battle/menu sounds: the project owner confirmed CC0; original creator handles/filenames and [battle](assets/audio/battle/License.txt) / [menu](assets/audio/menu/License.txt) declaration notes are retained.
- **Balsamiq Sans Bold**, bundled from [Google Fonts](https://github.com/google/fonts/tree/main/ofl/balsamiqsans): [SIL Open Font License](assets/fonts/OFL.txt). The font has its own license rather than the project's CC0 license.

## Scope and academic use

This is a local fighting-game prototype with one arena and one melee combo chain. Online multiplayer, gamepad bindings, runtime key rebinding, weapon-specific abilities, and a full competitive ruleset are not implemented. AI does not use machine learning.

For an academic report, document your design decisions, state transitions, frame-data experiments, test results, and evaluation. Disclose AI-assisted work according to your institution's requirements. The guides explain the implementation so you can adapt it and justify your own changes.

## Arena visual effects

Clouds drift slowly in opposite directions and wrap only after leaving the viewport. A knockout triggers a 1.4-second cinematic before the result screen: combat presentation runs at 25% speed, final-hit knockback continues, and the defeated fighter's equipped hat/helmet is hurled upward with rotation. No Hat produces no headgear prop. Double knockouts animate both defeated fighters; timeouts show results directly. The match clock and player actions stop during the cinematic, and rematches restore headgear. Cloud movement and audio keep normal timing.
