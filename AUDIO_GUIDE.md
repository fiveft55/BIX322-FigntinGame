# Audio guide for this project

## Files and events

Original supplied filenames are preserved under assets/audio.

| Event | File |
| --- | --- |
| Menu music | menu/mfcc-game-game-music-603130.mp3 |
| Play accepted | menu/freesound_community-game-start-6104.mp3 |
| Countdown 3 / 2 / 1 | voice/3.ogg, 2.ogg, 1.ogg |
| Countdown finishes | voice/fight.ogg; battle music starts |
| Battle music | battle/331music-video-game-music-598332.mp3 |
| Alternate battle track | battle/retro-bgm-chan-vs-robbot_vs-534622.mp3 |
| First active attack frame | battle/oxidvideos-video-game-sword-swing-sfx-409364.mp3 |
| Unblocked hit | battle/53439420-retro-hurt-sound-03-474780.mp3 |
| Front block/parry | battle/gargamel10-sword-slashing-game-sound-effect-2-379229.mp3 |
| Jump | battle/cartoon_music-kids-game-victory-504518.mp3 |
| Knockout cinematic starts | knockout/yarzur_ofc-sfx13-boss_damage2-324519.mp3 |
| Knockout results | battle/soundreality-game-over-man-136233.mp3 |
| Winner | voice/player_1.ogg or player_2.ogg, then winner.ogg |
| Draw | voice/it's_a_tie.ogg |
| Timeout results | voice/time.ogg, then player/winner or tie |

The jump file was supplied in the jump folder despite its victory-style filename; it is a musical cue. Original audio is not trimmed. Unused mode/count clips remain available but are not mapped to nonexistent game modes.

## Base mix and volume settings

| Player | Base Volume dB | Bus |
| --- | --- | --- |
| Menu Music | -17.721133 | Music |
| Menu StartSound | -10 | SFX |
| Battle Music | -17.721133 | Music |
| Announcer | -3 | Voice |
| Effects template/pool | -10 | SFX |
| Knockout hurt cue | -6 | SFX |

Battle music's current gain is 30% above its original -20 dB setting: 20 × log10(1.3) ≈ +2.279 dB. The Settings sliders apply separate linear 0–100% bus gains on top of these base mixes. Zero mutes a bus. Music affects menu and battle, Effects includes start/normal combat/knockout, Voice controls the announcer.

Swap menu streams in main_menu.tscn. Swap battle effects/voices using MatchAudio root Inspector fields in match_audio.tscn; select player nodes for stream/base volume. Keep the Music, Announcer, Effects, and Knockout names intact. default_bus_layout.tres defines independent buses.

## Playback behavior

Menu and battle MP3 resources are duplicated before enabling their loop flags; imported source resources are not modified. Entire tracks repeat. No crossfade or authored seamless loop points are implemented.

Fighter.combat_sound emits sword/hit/block/jump; Arena connects both fighters to MatchAudio.on_combat_sound. Up to eight effect players overlap. If all are busy, the first is reused. Numbered voices replace the prior countdown clip at one-second checkpoints. Results use a sequential queue advanced by Announcer.finished.

The final-hit cue has a dedicated player, starts with the losing-player cinematic, and is not cut off by result transitions. Battle music continues through the cinematic, then stops for results. Reset/menu exit stops old audio and clears voice queues; streams are released on scene exit. Cinematic slow motion does not change pitch or playback speed.

## Tests and listening

Audio and cinematic tests verify routing, loop flags, event timing, result ordering, final-hit cue, and cleanup. Menu tests verify live bus controls and persistence. Tests wait briefly for the audio mixer before scene destruction. Headless tests cannot evaluate sound quality, perceived loudness, speaker clipping, or musical loop boundaries; test those on a desktop.

## Licensing

Kenney Voiceover Pack has its original [CC0 license](assets/audio/voice/License.txt). The project owner confirmed CC0 for battle/menu packs; declaration notes and original filenames are preserved in their folders. The separately supplied knockout MP3 had no accompanying license document; its filename/source is recorded here without assigning a new license. Font licensing is separate; see README credits.
