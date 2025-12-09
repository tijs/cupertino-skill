# Releasing Cupertino 4.0.0: New Features and Hard Lessons in Release Engineering

**December 9, 2025**

Today I released Cupertino 4.0.0, and it was... an adventure. What should have been a straightforward release turned into a masterclass in why release engineering is hard and why automation exists.

## What's New in 4.0.0

First, the good stuff. This release brings some significant improvements:

### Human Interface Guidelines Support

Cupertino can now crawl and index Apple's Human Interface Guidelines. This was issue #69, and it's been on my list for a while.

```bash
cupertino fetch --type hig
```

There's also a new `search_hig` MCP tool that lets AI agents search design guidelines with platform and category filters. So now when you ask Claude "what are Apple's recommendations for buttons?", it can actually look it up.

### Framework Aliases

This one's subtle but important. Before, if you searched for "Core Animation", you might not find results indexed under "QuartzCore" (the actual framework import name). Now there are 249 framework aliases in the database, so searches work regardless of which name variant you use:

- `QuartzCore` ↔ `CoreAnimation` ↔ `Core Animation`
- `CoreGraphics` ↔ `Quartz2D` ↔ `Quartz 2D`

### Swift.org Fixes

The Swift.org crawler was broken. The base URL had changed from `docs.swift.org` to `www.swift.org/documentation/`, and the indexer was looking for `.md` files when the crawler was saving `.json` files. Classic.

## The Release Process Disaster

Here's where it gets interesting. I had all the code ready, all the tests passing, and I was ready to ship. The process seemed simple:

1. Bump version in `Constants.swift`
2. Update `README.md` and `CHANGELOG.md`
3. Create git tag
4. Push tag (triggers GitHub Actions build)
5. Upload databases to `cupertino-docs`
6. Update Homebrew formula

What could go wrong?

### The Tag Timing Problem

I merged my feature branch, created the tag, pushed it... and then realized I hadn't committed the version bump to `main` yet. The tag pointed to a commit where `Constants.swift` still said `0.3.5`.

GitHub Actions dutifully built a beautiful, signed, notarized universal binary... that reported version `0.3.5`.

```bash
$ cupertino --version
0.3.5
```

When users ran `cupertino setup`, it tried to download databases from `v0.3.5` instead of `v4.0.0`. Everything was broken.

### The Fix

I had to:

1. Delete the tag on GitHub
2. Delete the local tag
3. Make sure the version bump commit was pushed to `main`
4. Verify the built binary reports correct version **before** tagging
5. Recreate the tag
6. Wait for GitHub Actions to rebuild
7. Update the Homebrew formula with the new SHA256 (because the binary changed)

### The SHA256 Dance

Speaking of Homebrew—when I first updated the formula, I grabbed the SHA256 from the old (broken) binary. After rebuilding, the checksum changed. Users got:

```
Error: Formula reports different checksum: cf035352...
SHA-256 checksum of downloaded file: 5c5cf7ab...
```

Another round of updating the tap.

## The Current Release Process

After today's adventures, here's what the release process actually looks like:

```bash
# 1. Update version everywhere
edit Packages/Sources/Shared/Constants.swift  # version = "X.Y.Z"
edit README.md                                 # Version: X.Y.Z
edit CHANGELOG.md                              # Add new section

# 2. Commit and push (BEFORE tagging!)
git add -A && git commit -m "chore: bump version to X.Y.Z"
git push origin main

# 3. Verify version is correct
grep 'version = ' Packages/Sources/Shared/Constants.swift
make build && ./Packages/.build/release/cupertino --version

# 4. Only now create the tag
git tag -a vX.Y.Z -m "vX.Y.Z - Description"
git push origin vX.Y.Z

# 5. Wait for GitHub Actions to build (~5 min)

# 6. Create GitHub release with notes

# 7. Build locally and install
make build && sudo make install

# 8. Upload databases
export GITHUB_TOKEN="cupertino-docs-token"
cupertino release

# 9. Get new SHA256
curl -sL https://github.com/.../cupertino-vX.Y.Z-macos-universal.tar.gz.sha256

# 10. Update Homebrew tap
cd /tmp && git clone .../homebrew-tap.git
# Edit Formula/cupertino.rb with new version and SHA256
git commit && git push

# 11. Verify on fresh machine
brew update && brew install cupertino
cupertino --version
cupertino setup
```

That's 11 steps across 4 different repositories (`cupertino`, `cupertino-docs`, `homebrew-tap`, and GitHub Actions). Each step depends on the previous one. Miss one, and you're rebuilding everything.

## Time for Automation?

I'm seriously considering writing a release script. The question is: Swift or Bash?

**Arguments for Swift:**
- It's what the project is written in
- Type safety would catch some mistakes
- Could reuse existing code (like the GitHub API client from `ReleaseCommand.swift`)
- Cross-platform if we ever need it

**Arguments for Bash:**
- Simpler for orchestrating CLI commands
- No compilation step
- Everyone knows Bash (sort of)
- GitHub Actions scripts are basically Bash anyway

I'm leaning toward Swift, honestly. The `cupertino release` command already handles database uploads with proper GitHub API integration. Extending it to handle the full release workflow would be cleaner than maintaining a separate Bash script.

Something like:

```bash
cupertino release --full
```

That would:
1. Check for uncommitted changes
2. Verify version consistency across all files
3. Build and verify the binary version matches
4. Create and push the tag
5. Wait for GitHub Actions
6. Upload databases
7. Update the Homebrew tap

## Lessons Learned

1. **Order matters.** Commit the version bump before creating the tag. Seems obvious in retrospect.

2. **Verify before you ship.** Build the binary locally and check `--version` before tagging. Don't trust that "it should work."

3. **Document your release process.** I now have a detailed `DEPLOYMENT.md` with warnings about the order of operations.

4. **Automate what hurts.** If you make the same mistake twice, write a script. I made this mistake once—hopefully that's enough motivation.

## What's Next

- Fix the setup command animations (#96—they're completely broken)
- Consider that release automation script
- Maybe look at semantic-release or similar tools

For now, 4.0.0 is out. HIG support works. Framework aliases work. Swift.org is properly indexed again.

And I've learned more about release engineering than I wanted to in one afternoon.

---

*Cupertino is an Apple Documentation MCP Server. Check it out at [github.com/mihaelamj/cupertino](https://github.com/mihaelamj/cupertino).*
