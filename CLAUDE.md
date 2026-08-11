# CyberpunkMonsterCrawl_03

## Overview
A portrait-and-landscape iOS survivor game: the player runs through an
endless, procedurally generated neon city on an isometric grid, auto-firing
at raccoon swarms and surviving as long as possible. A run ends in death,
reports a summary, and RUN AGAIN regenerates the city with a new seed. The
authoritative spec is `design-brief-v2.md` (not yet added to this repo);
`docs/bootstrap.md` records what was asked for at bootstrap time.

## Tech stack
- Swift, iOS 16+
- SpriteKit hosted in UIKit (`SKView` in a `UIViewController`) — no SwiftUI
  game layer, so all layering (world/HUD/overlay) is governed by one
  z-position contract
- XCTest for tests
- XcodeGen (`project.yml`) generates the `.xcodeproj` — never hand-edit or
  commit the generated project

## Run locally
```
./setup.sh   # installs XcodeGen if missing, runs `xcodegen generate`, opens Xcode
```
Manual fallback: `brew install xcodegen && xcodegen generate`, then open
`CyberpunkMonsterCrawl.xcodeproj` and run the `CyberpunkMonsterCrawl` scheme
on an iOS Simulator.

## Run tests
⌘U in Xcode on the `CyberpunkMonsterCrawl` scheme, or:
```
xcodebuild test -scheme CyberpunkMonsterCrawl -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Current directory structure
```
project.yml
setup.sh
CyberpunkMonsterCrawl/
  Info.plist                                — hand-authored, XcodeGen-managed via `info:` (implemented)
  App/
    CyberpunkMonsterCrawlApp.swift           — @main app entry, legacy AppDelegate.window lifecycle (implemented)
    GameViewController.swift                 — hosts an empty SKView/SKScene (implemented)
  Assets.xcassets/                           — empty root asset catalog, populated in PR 2 (implemented)
  PrivacyInfo.xcprivacy, *.entitlements      — structural stubs (implemented)
CyberpunkMonsterCrawlTests/
  BootstrapSmokeTests.swift                  — one smoke test (implemented)
```

## Planned architecture (from docs/bootstrap.md)
- `GameState` machine: `menu → gameplay → death → highScores` (deferred)
- Menu scene with working PLAY button (deferred)
- Three-layer node stack `worldLayer < hudLayer < overlayLayer` with an
  ordering-invariant test (deferred)
- `IsoGrid`: 96×48 2:1-diamond tiles, round-trip tile↔screen conversion,
  pixel-perfect rendering helpers (integer scale, device-pixel snapping,
  nearest-neighbour filtering) (deferred)
- Asset contract: 10 atlas sheets + 12 building imagesets, one owning list
  per sprite family, tests that fail on any missing sheet/cell/file
  (deferred)
- Depth model: bands of `-(tileX+tileY)*10`, ground plane 5000 below all
  bands, buildings keyed off far corner, actor tile rounding, player drawn
  last in its band (deferred)
- City lattice: 3×3 building blocks separated by 3-tile street corridors on
  a 6-tile period; street corridor is the navmesh; deterministic
  `(tileX, tileY, seed)` generation (deferred)
- Injectable dice roller for testable combat (deferred)
- Player/raccoon sprite animation, weapons overlay, pulse attack (deferred)
- Pickup spawn/despawn system (deferred)
- Score (`damage + killBonus + seconds×level`) and local high-score
  persistence (deferred)
- Camera-follow over the generated ground plane (deferred)
- App Store submission prep: real icon art, launch screen art, store
  screenshots, TestFlight (deferred)

## Deferred work
See `bootstrap_plan.md` → "Out of scope" for the full, current list. In
short: everything above marked "(deferred)", plus audio (explicitly
deferred by the spec itself), Game Center/cloud sync/sharing, and
pause/resume/settings/meta-progression.

## Git Workflow

> **Default PR target branch: `develop`.** Every feature/refactor/docs PR
> opens against `develop`. PRs are only opened against `qa`, `uat`, or
> `main` for explicit promotion PRs.

**Branch model (`develop` → `qa` → `uat` → `main`):**

| Branch  | Role                                 | Receives PRs from              | Promotes to |
|---------|--------------------------------------|---------------------------------|-------------|
| develop | Default integration branch           | feature branches                | qa          |
| qa      | First quality gate                   | develop (promotion PR)          | uat         |
| uat     | Pre-prod acceptance                  | qa (promotion PR)               | main        |
| main    | Production / release tags            | uat (promotion PR)              | tagged only |

All feature PRs MUST target `develop`. Never open a feature PR against
`qa`, `uat`, or `main`. Promotions happen via dedicated promotion PRs.
