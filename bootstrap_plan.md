# Bootstrap Plan — CyberpunkMonsterCrawl_03

> **Superseded.** This is the historical plan for the initial ad-hoc
> bootstrap. CYBERPUN-16-1 PR 1 replaced the `AppDelegate`/`SceneDelegate`/
> `GameScene` shell described below with the officially specced scaffold
> (`CyberpunkMonsterCrawl/App/CyberpunkMonsterCrawlApp.swift` +
> `App/GameViewController.swift`, a hand-authored `Info.plist`, a root
> `Assets.xcassets`, and `CyberpunkMonsterCrawlTests/BootstrapSmokeTests.swift`).
> See `AGENT.md`/`CLAUDE.md` → "Current directory structure" for the live
> layout. Kept here for history only.

## In scope (this PR)

A runnable iOS Hello-World shell proving the SpriteKit toolchain works. No
game systems, no asset contract, no isometric grid, no state machine beyond
the app launching to a single visible screen.

**Tech-stack decisions:**
- Language: Swift, iOS 16+ deployment target
- Framework: SpriteKit (UIKit host — `SKView` inside a `UIViewController`,
  per the spec's "no SwiftUI game layer" decision)
- Test framework: XCTest (unit test target via XcodeGen)
- Project generation: XcodeGen (`project.yml`) — no hand-crafted `.xcodeproj`
- Layout: flat source root `CyberpunkMonsterCrawl/` (matches spec's lack of an
  explicit convention); future PRs will add `Game/`, `World/`, `Assets/`
  subdirectories as those systems land

### Directory structure

```
project.yml
setup.sh
.gitignore
docs/
  bootstrap.md
CyberpunkMonsterCrawl/
  AppDelegate.swift
  SceneDelegate.swift
  GameViewController.swift
  GameScene.swift
  PrivacyInfo.xcprivacy
  CyberpunkMonsterCrawl.entitlements
  Resources/
    Assets.xcassets/
      Contents.json
      AppIcon.appiconset/
        Contents.json
CyberpunkMonsterCrawlTests/
  CyberpunkMonsterCrawlTests.swift
CLAUDE.md
AGENT.md
README.md
bootstrap_plan.md
```

### Files this PR creates
- `project.yml` — XcodeGen spec: one app target (`CyberpunkMonsterCrawl`), one
  unit-test target, CI-hardening settings (no code signing, no script
  sandboxing), entitlements wiring, iOS 16 deployment target
- `CyberpunkMonsterCrawl/AppDelegate.swift` — UIKit app entry, wires
  `SceneDelegate` in code
- `CyberpunkMonsterCrawl/SceneDelegate.swift` — creates window, sets root VC,
  `makeKeyAndVisible()`
- `CyberpunkMonsterCrawl/GameViewController.swift` — hosts an `SKView`,
  presents `GameScene`
- `CyberpunkMonsterCrawl/GameScene.swift` — one `SKLabelNode` reading
  "CyberpunkMonsterCrawl_03" centered on a dark background — the trivial
  visible output
- `CyberpunkMonsterCrawl/Resources/Assets.xcassets/...` — stub AppIcon set
  (required so `actool` doesn't fail CI)
- `CyberpunkMonsterCrawl/PrivacyInfo.xcprivacy` — stub privacy manifest
- `CyberpunkMonsterCrawl/CyberpunkMonsterCrawl.entitlements` — stub keychain
  access group (harmless boilerplate, unblocks future Keychain-touching code)
- `CyberpunkMonsterCrawlTests/CyberpunkMonsterCrawlTests.swift` — one test
  instantiating `GameViewController` to prove the test target links against
  the app module
- `.gitignore` — standard XcodeGen iOS ignores
- `setup.sh` — installs XcodeGen if missing, runs `xcodegen generate`, opens
  the project
- `CLAUDE.md` / `AGENT.md` — project overview, planned architecture, deferred
  work, git workflow
- `README.md` — short pointer to setup + docs

### How to run locally
1. `./setup.sh` (installs XcodeGen via Homebrew if missing, generates
   `CyberpunkMonsterCrawl.xcodeproj`, opens it in Xcode)
2. Run the `CyberpunkMonsterCrawl` scheme on an iOS Simulator
3. App launches to a screen showing the label "CyberpunkMonsterCrawl_03"

### How to run tests
- In Xcode: ⌘U on the `CyberpunkMonsterCrawl` scheme (runs the
  `CyberpunkMonsterCrawlTests` target)
- CLI: `xcodebuild test -scheme CyberpunkMonsterCrawl -destination 'platform=iOS Simulator,name=iPhone 15'`

### Definition of Hello World
App launches on the simulator to a single dark screen with a centered label
reading "CyberpunkMonsterCrawl_03", rendered via an `SKScene` inside an
`SKView`. One XCTest proves the view controller compiles/links.

## Out of scope — deferred to future work

- The full `GameState` machine (`menu → gameplay → death → highScores`)
- Menu scene with working PLAY button
- Three-layer node stack (`worldLayer` / `hudLayer` / `overlayLayer`) and its
  ordering-invariant test
- `IsoGrid` (96×48 tile, 2:1 diamond) with tile↔screen round-trip conversion
  and pixel-perfect rendering helpers
- Asset catalog contract: 10 atlas sheets, 12 building imagesets, owning
  lists, negative missing-image tests
- Depth-model implementation (band formula, ground plane offset, actor/
  building z-ordering)
- City lattice generation: 3×3 building blocks, 3-tile street corridors,
  navmesh guarantee, deterministic `(tileX, tileY, seed)` world generation
- Injectable dice roller for combat
- Player sprite animation (8-direction walk, weapons overlay, pulse attack)
- Raccoon swarm sprites/AI, elite scaling
- Pickup spawn/despawn system
- Score calculation and high-score local persistence
- Camera-follow behavior over the generated ground plane
- Portrait/landscape re-layout logic beyond basic Auto Layout
- Audio (explicitly deferred by the spec itself)
- App Store submission prep (real app icon art, launch screen art, store
  screenshots, TestFlight — the bootstrap's icon/privacy files are structural
  stubs only)
- Game Center, cloud sync, sharing
- Pause/resume, settings, meta-progression
