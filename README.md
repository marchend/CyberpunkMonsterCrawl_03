# CyberpunkMonsterCrawl_03

Cyberpunk neon-city survivor game — iOS + SpriteKit. This repo currently
ships the bootstrap Hello-World shell only; see `docs/bootstrap.md` for the
full spec and `bootstrap_plan.md` for what's in/out of scope for this PR.

## Setup
```
./setup.sh
```
Installs XcodeGen if missing, generates `CyberpunkMonsterCrawl.xcodeproj`,
and opens it in Xcode. Manual fallback:
```
brew install xcodegen && xcodegen generate
```

See `CLAUDE.md` / `AGENT.md` for architecture, run/test instructions, and
the git branching model.
