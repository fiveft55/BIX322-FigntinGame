# Menu guide for this project

## Navigation

The entry scene is `scenes/main_menu.tscn`. Home contains Player vs AI, Player vs Player, and Customize in a compact solid card. Selecting Player vs AI hides those controls and displays Play, Difficulty, and Main Menu in the same rows. Choose Easy/Normal/Hard and press Play. Main Menu or Escape restores the original controls. Player vs Player starts local play directly.

The upper-right cog opens Settings; the cross quits. Settings includes Music, Effects, Voice sliders and a Controls button. Controls Back returns to Settings. Customize opens both players' body, weapon, and hat choices; Save & Back returns to Home. Escape from a fight returns to the menu. Result buttons are Play Again and Main Menu, without Quit or health numbers.

## Current scene layout

| Element | Current configuration |
| --- | --- |
| Background | Original Kenney Sample.png, aspect-cover TextureRect |
| Title card | Solid cream, 480 × 90 pixels |
| Title / subtitle | Balsamiq Sans Bold 36 px / standard font 16 px |
| Home card | 240 × 195 pixels |
| Home controls | 210 × 45, 15 px inner padding and vertical gaps |
| Button/dropdown text | 18 px |
| Settings/Customize headings | 24 px |
| Toolbar | Anchored 40 px from top/right; two 64 px buttons with 15 px gap |
| Icons | tile_cog.png and ui_numXlarge.png, centered with 12 px inner padding |

Panels use `menu_theme.tres`: cream cards, navy text/buttons, teal hover/pressed states, and gold keyboard-focus outlines. There is no full-screen background wash. Title and Home retain solid fills; game-over uses a separate translucent panel. Edit the scene rather than rebuilding layouts in code. Keep widget names used by main_menu.gd intact.

## AI difficulty

| Level | Attack decision interval | Movement multiplier | Reaction threshold | Guard window threshold |
| --- | --- | --- | --- | --- |
| Easy | 0.85 seconds | 0.8 | 10 attack timeline frames | 0.2 |
| Normal | 0.6 seconds | 1.0 | 4 attack timeline frames | 0.65 |
| Hard | 0.25 seconds | 1.1 | 1 attack timeline frame | 0.95 |

Profiles are `GameSettings.AI_DIFFICULTIES`. AI approaches when horizontally farther than 105 pixels and considers attacks within 145. Guard availability uses `fmod(ai_timer, 1.5) < profile.guard`, not a random percentage. Difficulty changes behavior, not damage/health. The AI is deterministic and remains ground-based.

## Customization

Eight body choices are round/square variants in Green, Purple, Red, and Yellow. Hands and health-bar colors follow body color. Weapon choices are Sword, Spear, Rod, and Pencil; all share the tested melee combo and hitboxes. Hats are No Hat, Cap, Top Hat, Helmet, and Modern Helmet, with no stat effects.

Catalogs live in `GameSettings.CHARACTERS`, `WEAPONS`, and `HATS`. Add valid names/paths there to populate dropdowns automatically. Selections apply to live previews and fighter sprites. Saved texture choices override fighter scene default art at runtime; transforms remain scene-editable. Existing saved indices are positional: reordering a catalog changes what old preferences select. A real weapon ability requires additional gameplay, not just another texture.

## Saved settings

Preferences stores ConfigFile data in `user://settings.cfg`:

| Section | Keys |
| --- | --- |
| game | difficulty |
| audio | music, effects, voice (linear 0..1) |
| players | character_0/1, weapon_0/1, hat_0/1 |

Changes apply and save immediately. Music controls menu/battle tracks; Effects controls start/combat/knockout cues; Voice controls the announcer. Zero mutes the bus. Default per-player dB mix levels still apply. Match mode is runtime-only. On desktop, user:// uses Godot's application-data directory; in the cloud it follows XDG_DATA_HOME.

To return to defaults, close the game and remove the settings.cfg file from its application-data location. Do not delete assets or repository files. Tests use a separate settings file and restore runtime options.

## Mode-specific shortcuts

R/reset, H/boxes, and Tab/AI toggle are available only in matches launched via Player vs AI. That practice mode remains eligible after Tab temporarily switches the opponent to manual input. Matches launched via Player vs Player ignore all three keys. Escape and result-screen navigation work in either mode.

## Menu audio and font

Menu music is `mfcc-game-game-music-603130.mp3`; start cue is `freesound_community-game-start-6104.mp3`, under assets/audio/menu. Select Music/StartSound in the scene to swap streams and base volume. Music loops and stops when Play is accepted. Battle starts after the voiced countdown.

Title font is bundled Balsamiq Sans Bold from the [official Google Fonts repository](https://github.com/google/fonts/tree/main/ofl/balsamiqsans). It works offline under [SIL OFL](assets/fonts/OFL.txt), separately from CC0 art. Edit Title font/size in the scene.

`tests/menu_test.gd` checks navigation, layout/font fit, persistence, selected art, palette bars, play modes, shortcut restrictions, and actual Easy/Hard behavior. Desktop playtesting is still required for final visual spacing and sound mix.
