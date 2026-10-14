# Included Kenney artwork

Source: user-uploaded kenney_scribble-platformer.zip. Creator: Kenney (https://kenney.nl). The Retina PNG set is in assets/scribble; the original CC0 license is preserved in assets/scribble/License.txt. The pack has static images and no audio or animation sheets. Unused textures remain available for customization.

Player1 uses character_roundGreen and character_handGreen; Player2 uses character_squarePurple and character_handPurple. Both use item_sword, item_shieldRound, and effect_blast. Arena scenery uses background_cloudA/B, background_tree/treeLarge, tile_castle, tile_bush, tile_grass, and tile_brick.

All artwork is now stored as editable Sprite2D nodes in scenes/arena.tscn, scenes/fighter_green.tscn, and scenes/fighter_purple.tscn. Texture paths and placement are no longer loaded/drawn by gameplay scripts. See [SCENE_GUIDE.md](SCENE_GUIDE.md) for editor placement, sword pivots, swapping textures, and matching collision boxes.
