# Main menu, settings, and character selection

The project starts in scenes/main_menu.tscn. Open it in Godot's 2D editor to rearrange the Home, Settings, Controls, and Characters panels. All buttons, labels, sliders, character previews, and music players are scene-authored.

## Play and controls

Home offers Play vs AI, Local Two Players, AI difficulty, Characters & Weapons, Settings, Controls, and Quit. Pick characters/weapons before pressing Play. Play uses the uploaded start cue, then enters the existing three-second voiced countdown. Menu music loops until Play; battle music starts at FIGHT!. Escape returns from a fight to the menu; the result screen also offers Main Menu. Escape in submenu pages goes back to Home.

The Controls page reads current keys from GameSettings.KEYS, so editing bindings updates the displayed information automatically. It explains player movement, jumping, sword/melee attacks, shield/parries, restart, diagnostics, and match rules. It displays information, not a key rebinding UI.

## AI difficulty

Easy, Normal, and Hard are configured in GameSettings.AI_DIFFICULTIES. Difficulty changes attack decision interval, horizontal speed multiplier, minimum observed attack-frame reaction, and guard availability. Damage, health, and player controls do not change. Easy waits 0.85 seconds between decisions with 0.8 movement; Normal uses 0.6/1.0; Hard uses 0.25/1.1. Hard therefore queues combos more often and reacts to guard opportunities earlier. This is deterministic rule-based AI, not machine learning.

## Characters and weapons

Both players have eight choices: round/square bodies in Green, Purple, Red, and Yellow. Hands match the chosen color. Four available melee art choices are Sword, Spear, Rod, and Pencil. All use the existing three-strike melee FSM, timing, and hitboxes; selecting a spear or pencil does not add projectile attacks or different stats. Shield art remains shared. The colored preview strip and in-game health bar use the character's palette.

GameSettings.CHARACTERS defines names, body/hand textures, and health-bar colors. GameSettings.WEAPONS defines display names and texture paths. Add choices there with valid imported assets. Menus populate automatically. Fighter._ready() applies saved selection textures to the existing scene nodes; scene positions and weapon pivots remain editable. Selected textures override the green/purple scene default textures at runtime. For radically different weapon dimensions, adjust the scene's SwordGrip/Sword transforms and collision reach together. The node is still named Sword for compatibility with the pose script.

## Sound and persistence

Settings has Music, Effects, and Voice sliders (0–100%). They apply instantly to separate AudioServer buses. Music affects both menu and battle tracks; Effects includes jump, attacks, hits, and the start cue; Voice controls the announcer. Zero mutes the bus. Player-specific Volume dB in the audio scenes remains the base mix, multiplied by the bus slider value.

Preferences is an autoload from scripts/preferences.gd. It saves difficulty, character/weapon/hat choices, and volumes to user://settings.cfg. Missing files use defaults; loaded values are clamped to supported ranges. The chosen local/AI play mode is a runtime choice. On desktop, user:// is Godot's application-data directory; in the cloud it follows the documented XDG_DATA_HOME. Tests use a separate settings file so they do not overwrite user preferences.

Menu sound filenames from the uploaded menu.zip are preserved under assets/audio/menu: mfcc-game-game-music-603130.mp3 and freesound_community-game-start-6104.mp3. The project owner's CC0 declaration is recorded there. Select Music/StartSound in main_menu.tscn to swap files or change base volume.

## Verification

Run tests/menu_test.gd alongside the README suites. It checks looping menu music, opening settings, live bus mute/volume, saved options, character/weapon application, health color, both play modes, menu return, and actual Easy/Hard AI behavior. Headless tests cannot evaluate how the music sounds or visual spacing; desktop playtesting is recommended.

## Hats, background, and practice-only shortcuts

Characters now includes a hat selector for each player: No Hat, Cap, Top Hat, Helmet, and Modern Helmet from the original pack. GameSettings.HATS defines names and paths. Preferences.hats saves choices. Hat is a Sprite2D child of Body in each fighter scene and menu preview, so it follows body motion and facing. Edit its local position/scale in the scenes to adjust fit.

MainMenu/Background uses the pack's original Sample.png via a full-size TextureRect with aspect-cover scaling; Opaque cream panels and a TitleCard keep text legible without washing out the image. Edit Background/TitleCard for placement and menu_theme.tres for panel and button styling. The original unmodified sample retains Kenney's artwork and attribution.

R, H, and Tab practice controls are ignored in matches launched with Local Two Players. AI practice matches allow them, including toggling the practice opponent temporarily to manual control and back. The match mode is captured at launch, so a local match cannot be converted to AI using Tab. Escape and result-screen Play Again/Main Menu remain available in either mode. Quit is removed from results and remains on the main menu.

Menu styling uses solid cream cards, dark text, navy buttons, teal hover states, and gold keyboard-focus borders. The sample background has no full-screen transparency wash and remains visible at full contrast around the cards.

## Updated home layout and title font

Title and Home use compact solid cream cards. Home is 240 × 195 pixels initially and expands to 542 × 195 when AI controls are revealed. The upper-right toolbar is anchored 40 pixels from the top/right viewport edges with 64-pixel icon buttons and a 15-pixel gap: Kenney tile_cog for Settings and ui_numXlarge for Quit. Controls is reached from Settings; Back returns to Settings. Customize opens characters, weapons, and hats.

Selecting Player vs AI reveals the difficulty dropdown to its right plus an explicit Play button; selection alone does not start the match. Player vs Player starts local play directly.

The title uses Balsamiq Sans Bold from Google Fonts' official repository, downloaded into assets/fonts/BalsamiqSans-Bold.ttf. It is bundled for offline use under the included SIL Open Font License (assets/fonts/OFL.txt), separate from the CC0 artwork. Source: https://github.com/google/fonts/tree/main/ofl/balsamiqsans. Other text retains its readable standard font. Edit Title's font/size in main_menu.tscn.

The title is now 36 px with a 480 × 90 card; its subtitle is 16 px. Home buttons have 15 px vertical spacing and inner padding. The AI dropdown and Play button retain 15 px horizontal spacing.

Menu buttons and dropdowns use 18 px text, page headings 24 px, and the title 36 px to fit the compact cards.

Player vs AI now toggles the same compact card to Play, Difficulty, and Main Menu in the three original rows. Original menu buttons hide while this submenu is open; Main Menu or Escape restores them. No wider panel is needed.
