# CC0 combat recordings

Downloaded 2026-11-11. Both source pages explicitly label these assets CC0.

- StarNinjas — **20 Sword Sound Effects (Attacks and Clashes)**
  https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes
  https://opengameart.org/users/starninjas
  Archives: `sword_-_starninjas_1.zip`, `sword_clash_-_starninjas_0.zip`.
- Iwan 'qubodup' Gabovitch — **Impact**
  https://opengameart.org/content/impact
  https://opengameart.org/users/qubodup
  Archive: `qubodupImpact.7z`; lossless FLAC sources used.

CC0: https://creativecommons.org/publicdomain/zero/1.0/

Processing: decode to float (avoid clipping lossy overshoots), trim silence,
peak-match to 0.72, 0.8 ms entry / 6 ms exit fades, mono 44.1 kHz PCM16 WAV.
No synthesis or generated sound replacement. Individual provenance, original hashes,
trim and gain values are in manifest.json. Small playback pitch variation is applied
in-game. Source-page snapshots are retained beside this notice.
