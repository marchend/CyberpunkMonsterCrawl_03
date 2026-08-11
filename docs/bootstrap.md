# Bootstrap — CyberpunkMonsterCrawl_03

## What we're building

A portrait-and-landscape iOS survivor game: the player runs through an endless,
procedurally generated neon city on an isometric grid, auto-firing at raccoon
swarms and surviving as long as possible. A run ends in death, reports a summary,
and RUN AGAIN regenerates the city with a new seed. The MVP finish line is a
playable game on the simulator with the brief's ten product gates demonstrated;
App Store submission work is a later backlog.

Authoritative document: `design-brief-v2.md` (it explicitly supersedes v1). The
three Claude Design HTML exports are source-of-record only and are never
imported — MothershipCode ingests the PNGs.

## Stack decisions

- **Swift + SpriteKit, iOS 16+.** The brief names SpriteKit, and the game is 2D
  sprite-atlas pixel art with a painter's-algorithm depth model — SpriteKit's
  node tree and `zPosition` map onto it directly. No SwiftUI game layer; menus
  and HUD are SpriteKit nodes so layering is governed by one z contract.
- **Both orientations supported** (user direction). Scenes resize and re-lay out
  on rotation; orientation is never locked.
- **No audio.** Deferred for this MVP by user direction.
- **Local persistence only** for high scores. No accounts, no network, no Game
  Center in this backlog.
- **Art is authored once at 1×.** Nearest-neighbour filtering, mipmaps off,
  whole-integer scale only, every sprite snapped to whole device pixels. No
  `@2x`/`@3x` renditions are ever added — the pack's "Asset Scales" sheet is a
  preview, not a second asset set.
- **Buildings are whole pre-rendered sprites, placed not built.** The renderer
  decides only WHICH sprite, WHERE, and in WHAT depth order. Procedural building
  geometry is banned by the brief as the main cause of render-vs-art drift.
- **Determinism by construction.** World generation is a pure function of
  `(tileX, tileY, seed)`; all dice go through one injectable roller so combat is
  testable.

## Key contracts to establish first

1. **Asset contract before consumers.** 10 atlas sheets sliced on measured cell
   grids plus 12 whole building imagesets, with one owning list per sprite
   family and a test suite that fails if any sheet, cell index or building file
   is missing. Measure programmatically, never infer from a filename. This is
   the v1 failure class (v1 shipped an empty catalog, all tests green).
2. **Layer contract.** `worldLayer` < `hudLayer` < `overlayLayer`, enforced by
   named constants and a test. v1 rendered the world over the UI and no input
   worked at all.
3. **Depth model, written down before the first renderer PR.** Bands of
   `-(tileX+tileY) * 10`; ground plane 5000 below all bands; a building is one
   sprite keyed off its FAR corner (greatest `tileX+tileY`), no per-face
   sorting; actors sample their ROUNDED tile; building in-band content under
   `+3`, actor offsets `6.5–9.9`; the player draws LAST in its band so a tower
   can never hide him.
4. **The city lattice connectivity guarantee.** 3×3 building blocks separated by
   a THREE-tile street corridor on both axes (6-tile period). The street
   corridor IS the navmesh; buildings are solid collision by flat footprint
   regardless of drawn height; every intersection tile is street under every
   seed. Do not weaken this — it is what guarantees the player and the swarm
   always have a path.

## First runnable shell

- iOS app target that launches into a menu with a working PLAY button.
- `GameState` machine: `menu → gameplay → death → highScores`.
- The three-layer node stack with the ordering invariant under test.
- `IsoGrid` (tile 96×48, 2:1 diamonds) with round-trip tile↔screen conversion,
  plus the pixel-perfect helpers (integer render scale, device-pixel snapping,
  nearest filtering).
- The asset catalog fully populated and covered by the contract tests, including
  a negative test that fails when an image id is removed.
- A camera-followed world layer drawing the generated ground plane, so a
  developer can pan around a real city block lattice on day one.
- Any debug affordance carries a `// SCAFFOLDING:` marker so it can be grepped
  out before the final milestone.

## Measured facts worth carrying into code

- Tile: 96×48, 2:1 diamonds (supersedes any earlier 128×64 figure).
- Chunks: 8×8 tiles, streamed with hysteresis, byte-identical on reload.
- Player: `sprite_player_walk.png` 144×320, cell 36×40, 8 directions (5 authored,
  rows 5–7 mirror 3/2/1), 4 frames, 8 fps, anchor 18,40, hitbox 14×10.
- Raccoons: two 192×224 sheets, cell 48×28, 8 directions, walk 10 fps / attack
  12 fps, anchor 23,20, elites drawn 1.6×.
- Weapons: `sprite_player_weapons.png` 288×120 overlay on the same 36×40 cell —
  row 0 handgun, row 1 SMG at level 3, row 2 assault rifle at level 6, auto only.
- Pulse: push to just past the radius edge, 1d6, +1d6 when wall-pinned; radius
  +25% at level 3, +25% again and die → 1d8 at level 6; short cooldown.
- Pickups (tuned — keep): first spawn 8s, cadence 25s, max 2 alive per kind,
  lifetime 20s expiring by age never by camera distance; street tiles only with
  all 8 neighbours building-free; 32×32pt icon bobbing over a tinted pad.
- Score: `damage + killBonus + seconds × level`.

## Explicitly deferred

- Audio (SFX and music).
- App Store prep: app icon set, launch screen, bundle/version config, privacy
  manifest, store screenshots, TestFlight.
- Game Center leaderboards, cloud sync, sharing.
- Pause/resume, settings, meta-progression between runs.
- `tileset_structure.png` — source of record only; never imported. Consume the
  `buildings/` sprites.
- Adding new building art (more variety later means more sprites, not code).