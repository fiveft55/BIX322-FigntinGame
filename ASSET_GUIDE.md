# Kenney Scribble Platformer integration

Source: user-uploaded kenney_scribble-platformer.zip. Creator: Kenney (https://kenney.nl). The original license is included at assets/scribble/License.txt: Creative Commons Zero (CC0). Credit is optional; retained here for attribution. Imported files are the Retina PNG set; default PNG duplicates, vector/SWF files, and the Construct project are not needed by Godot and were not imported. The pack contains static images and no audio or character animation sheets.

## Asset mapping

| Role | Files in assets/scribble |
| --- | --- |
| Player 1 | character_roundGreen.png, character_handGreen.png |
| Player 2 | character_squarePurple.png, character_handPurple.png |
| Guard pose | item_shieldRound.png |
| Active punch effect | effect_blast.png |
| Sky decoration | background_cloudA.png, background_cloudB.png |
| Trees | background_tree.png, background_treeLarge.png |
| Scenery | tile_castle.png, tile_bush.png |
| Ground | tile_grass.png, tile_brick.png |

Other supplied Retina PNGs remain available for your own additions. They are not all used as game objects.

## Change characters

Edit CHARACTER_TEXTURES and HAND_TEXTURES in scripts/game_settings.gd. Each array contains player 1 then player 2. For example use character_roundRed.png with character_handRed.png. Texture paths must point to valid imported PNGs. Restart to load changes.

FighterVisual creates body/hand/shield/effect poses from static textures. Body artwork is drawn at 72 × 112 pixels around local (0, -56), with feet at the fighter origin. The source has transparent horizontal margins; this produces a roughly 45-pixel-wide visible body to match the existing 42 × 104 hurtbox. Hands use 64 × 64 texture rectangles with transparent margins. Edit dimensions/offsets in fighter_visual.gd when using different artwork; then adjust hurtbox constants if the new visible body differs. Mirroring affects only art, since hit detection already mirrors its own rectangles.

Attack extension is controlled by ATTACKS reach and state_frame. Startup retracts the fist; active frames extend it and show the blast; recovery retracts it. These visuals use the same combat timeline rather than independent animation timers. Walking bobs, jumps lean with velocity, stun tints/shakes, and guard displays the shield. Static images are not represented as authored animation sheets.

## Change the arena or UI

Edit arena_visual.gd's texture list and stamp() calls to choose scenery and positions. Ground tiles start at GameSettings.FLOOR_Y, the actual foot plane. Decorative trees, bushes, and castles have no collisions. Health-bar colors, labels, and fonts are configured in arena.gd.create_hud(). The neutral paper background keeps outlines readable. Collision overlays can be toggled with H (or your configured boxes key).

No combat timings, damage, key bindings, jump behavior, or queue semantics were changed by this asset integration. Run the README test commands after adjusting collision geometry or gameplay. A desktop playtest is still recommended for appearance and animation feel.
