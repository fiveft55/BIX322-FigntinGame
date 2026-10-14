# Sound mapping and volume controls

Audio comes from the uploaded battle.zip and kenney_voiceover-pack-fighter.zip. Original filenames are preserved under assets/audio. Kenney's original CC0 license is retained in voice/License.txt. The project owner confirmed the battle assets are CC0; battle/License.txt records that declaration. The new ZIP files were verified against the imported audio bytes.

## Events

| Event | Audio |
| --- | --- |
| Countdown 3 / 2 / 1 | Voice 3.ogg / 2.ogg / 1.ogg |
| Countdown finishes | Voice fight.ogg and battle music start |
| Sword's first active frame | oxidvideos-video-game-sword-swing-sfx-409364.mp3 |
| Unblocked damage | 53439420-retro-hurt-sound-03-474780.mp3 |
| Front shield block / parry | gargamel10-sword-slashing-game-sound-effect-2-379229.mp3 |
| Jump launch | cartoon_music-kids-game-victory-504518.mp3 (supplied jump folder) |
| Knockout result | soundreality-game-over-man-136233.mp3 |
| Winner | player_1.ogg or player_2.ogg, followed by winner.ogg |
| Draw | it's_a_tie.ogg |
| Timeout | time.ogg, then the result voice sequence |

Music uses 331music-video-game-music-598332.mp3 by default. The alternate retro-bgm-chan-vs-robbot_vs-534622.mp3 is included and can be swapped in the scene. Original audio is not trimmed or modified. The supplied jump clip is a short musical cue rather than a physical jump sound; replace it in the Inspector if you prefer another effect. No menu/mode voiceovers are triggered because those modes do not exist.

## Editor configuration

Open scenes/match_audio.tscn. Select MatchAudio to swap any exported effect or voice AudioStream by dragging a file into its Inspector field. Select Music to change the battle stream and Volume dB (default -17.72). Announcer has Volume dB -3; Effects has -10 and is used as the template for an eight-player effect pool. Lower dB means quieter. Voices are sequential; effects can overlap so simultaneous hits do not cut each other off.

Open Godot's Audio panel to adjust the Music, Voice, and SFX buses separately, or edit default_bus_layout.tres. The Music stream is duplicated at runtime and its MP3 loop flag is enabled; it repeats the entire track until the result screen. Headless tests verify loop configuration and event routing, not audible mix quality or a seamless musical transition. Desktop listening is recommended to tune volume and the loop boundary.

## Runtime flow

Fighter.combat_sound(event) emits sword, jump, hit, or block events. Arena connects both fighters to MatchAudio.on_combat_sound(). Countdown checkpoints select the numbered clips, and begin_battle() starts music/fight voice. finish_match() stops battle music/effects and queues the appropriate result clips; Announcer.finished advances the queue. Restart stops every old sound and begins a fresh countdown. _exit_tree() releases playback resources. The sound scene is created by the arena alongside the UI overlay.

Run tests/audio_test.gd with the README commands. It checks count timing, loop flag/start/stop, audio buses, event routing, result voice order, and rematch cleanup. Other tests allow the audio mixer a short cleanup interval before exiting.
