# Asset guide for this project

## Artwork

The original user-uploaded kenney_scribble-platformer.zip supplies the Retina PNG set under assets/scribble. Default-size duplicates, vector/SWF files, and the Construct project are not required. The unmodified Sample.png is also included for the main-menu background. Kenney's original [CC0 license](assets/scribble/License.txt) is retained.

| Role | Source textures |
| --- | --- |
| Bodies | character_round/square Green/Purple/Red/Yellow |
| Matching hands | character_hand Green/Purple/Red/Yellow |
| Weapons | item_sword, item_spear, item_rod, item_pencil |
| Headgear | item_hat, item_hatTop, item_helmet, item_helmetModern |
| Shield/effect | item_shieldRound, effect_blast |
| Clouds/trees | background_cloudA/B, background_tree/treeLarge |
| Arena decorations | tile_castle, tile_bushHalf |
| Ground | tile_top, tile_block |
| Menu background | Sample.png |
| Settings/quit icons | tile_cog, ui_numXlarge |

Static artwork is animated with transforms, not imported animation sheets. Extra PNGs remain available for additions but are not all game objects. Catalog paths are configured in GameSettings; scene nodes define placement. See [SCENE_GUIDE.md](SCENE_GUIDE.md) for rig/pivot/scale rules. Hats and weapons have no independent gameplay stats.

## Font and sound

Balsamiq Sans Bold is bundled from Google's official fonts repository under the included [SIL OFL](assets/fonts/OFL.txt), not CC0. It is used only for the main-menu title. No runtime download occurs.

Sound files are grouped into voice, battle, menu, and knockout directories. Source filenames are preserved. Original voice license and owner declarations for battle/menu are included. See [AUDIO_GUIDE.md](AUDIO_GUIDE.md) for mappings and the separate knockout upload's provenance.

## Import and version control

Add supported textures/audio/fonts under assets, allow Godot to import them, then reference them from scenes or catalogs. PNG/MP3/OGG/TTF source files, .import configuration files, .tscn/.tres resources, and .gd.uid identifiers belong in version control. The generated .godot cache is ignored and rebuilt on import.

For a replacement character, match feet to the fighter origin, align hands and weapon grip, and then tune receiving/attack rectangles. Art-only rescaling does not change collisions. Keep original license files with redistributed third-party assets and record the source of new additions.
