# Music

**Music by Frank Bria.** All rights reserved by the author; the music is part of this game and is not licensed for other use.

The game plays four tracks from this directory (#118). It looks for each under its name with the extension `.m4a`, then `.ogg`, then `.wav`, and uses the first it finds. A track that is missing is silent, and the game plays on without it.

| File | Plays | Shape |
|---|---|---|
| `menu_loop` | the menu and the screens reached from it | seamless loop, 60 to 90 s |
| `round_loop` | during play | seamless loop, 90 to 120 s |
| `fever_stinger` | the moment the bonus triggers, in place of the bonus sound effect | one shot, 2 to 4 s, leads into the fever loop |
| `fever_loop` | during the fever | seamless loop, 8 or 16 bars |

The masters (44.1 kHz 24-bit WAV at -18 LUFS and -1 dBTP) stay out of the repository. Encode each to AAC at about 128 to 160 kbps, for example:

```bash
ffmpeg -i menu_loop.wav -c:a aac -b:a 160k assets/music/menu_loop.m4a
```

Listen to each loop's seam on a phone or an emulator. If AAC leaves a click or a gap there, encode that loop to Ogg Vorbis (`-c:a libvorbis -q:a 5`, `.ogg`) or keep it as WAV instead; no code changes. The four files together should add no more than about 4 MB to the app.
