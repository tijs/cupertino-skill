# Cupertino Deployment Guide

**Version:** 0.3.5
**Last Updated:** 2025-12-08

This guide covers distributing Cupertino via Homebrew and GitHub releases.

---

## Table of Contents

1. [Installation Methods](#installation-methods)
2. [Homebrew Distribution](#homebrew-distribution)
3. [GitHub Releases](#github-releases)
4. [CI/CD Setup](#cicd-setup)
5. [Version Management](#version-management)
6. [Release Checklist](#release-checklist)

---

## Installation Methods

### 1. One-Command Install (Recommended)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/mihaelamj/cupertino/main/install.sh)
```

This downloads a pre-built, signed, and notarized universal binary.

### 2. Homebrew

```bash
brew tap mihaelamj/tap
brew install cupertino
cupertino setup
```

### 3. Build from Source

```bash
git clone https://github.com/mihaelamj/cupertino.git
cd cupertino
make build
sudo make install
```

---

## Homebrew Distribution

### Tap Repository

Cupertino is distributed via a custom Homebrew tap at [mihaelamj/homebrew-tap](https://github.com/mihaelamj/homebrew-tap).

### Formula Location

```
Formula/cupertino.rb
```

### Formula Template

```ruby
class Cupertino < Formula
  desc "Apple Documentation Crawler & MCP Server"
  homepage "https://github.com/mihaelamj/cupertino"
  url "https://github.com/mihaelamj/cupertino/releases/download/v0.3.5/cupertino-0.3.5-macos.tar.gz"
  sha256 "CHECKSUM_HERE"
  license "MIT"

  depends_on :macos
  depends_on macos: :sequoia

  def install
    bin.install "cupertino"
  end

  def caveats
    <<~EOS
      Cupertino has been installed!

      Quick Setup:
        cupertino setup    # Download pre-built databases
        cupertino serve    # Start MCP server

      Configure Claude Desktop:
        Edit ~/Library/Application Support/Claude/claude_desktop_config.json:
        {
          "mcpServers": {
            "cupertino": {
              "command": "#{bin}/cupertino"
            }
          }
        }

      Documentation: https://github.com/mihaelamj/cupertino
    EOS
  end

  test do
    assert_match "cupertino", shell_output("#{bin}/cupertino --help")
    assert_match version.to_s, shell_output("#{bin}/cupertino --version")
  end
end
```

### Updating the Formula

1. Build release binary:
   ```bash
   make build
   ```

2. Create tarball:
   ```bash
   cd Packages/.build/release
   tar -czf cupertino-0.3.5-macos.tar.gz cupertino
   ```

3. Calculate checksum:
   ```bash
   shasum -a 256 cupertino-0.3.5-macos.tar.gz
   ```

4. Update formula with new version and checksum

5. Test formula:
   ```bash
   brew install --build-from-source Formula/cupertino.rb
   brew test cupertino
   ```

6. Commit and push to tap repository

---

## GitHub Releases

### Creating a Release

1. **Tag the release:**
   ```bash
   git tag v0.3.5
   git push origin v0.3.5
   ```

2. **Build release artifacts:**
   ```bash
   make build
   cd Packages/.build/release
   tar -czf cupertino-0.3.5-macos.tar.gz cupertino
   ```

3. **Create release on GitHub:**
   - Go to Releases → Draft a new release
   - Select tag v0.3.5
   - Upload cupertino-0.3.5-macos.tar.gz
   - Add release notes

### Release Artifact Structure

```
cupertino-0.3.5-macos.tar.gz
└── cupertino              # Universal binary (arm64 + x86_64)
```

---

## CI/CD Setup

### GitHub Actions Workflow

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Setup Swift
        uses: swift-actions/setup-swift@v2
        with:
          swift-version: "6.0"

      - name: Build Release
        run: |
          cd Packages
          swift build -c release

      - name: Create Tarball
        run: |
          cd Packages/.build/release
          tar -czf cupertino-${{ github.ref_name }}-macos.tar.gz cupertino

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: Packages/.build/release/cupertino-${{ github.ref_name }}-macos.tar.gz
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Version Management

### Version Locations

Update version in these files when releasing:

| File | Location |
|------|----------|
| `Packages/Sources/Shared/Constants.swift` | `Constants.version` |
| `README.md` | Project Status section |
| `docs/ARCHITECTURE.md` | Header |
| `CHANGELOG.md` | New entry at top |

### Version Format

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

---

## Release Checklist

### Pre-Release

- [ ] All tests passing: `make test`
- [ ] No lint violations: `make lint`
- [ ] Update version in `Constants.swift`
- [ ] Update version in `README.md`
- [ ] Update version in `docs/ARCHITECTURE.md`
- [ ] Add CHANGELOG.md entry
- [ ] Commit version changes

### Release

- [ ] Tag release: `git tag v0.3.5`
- [ ] Push tag: `git push origin v0.3.5`
- [ ] Build: `make build`
- [ ] Create tarball
- [ ] Create GitHub release
- [ ] Upload artifacts

### Post-Release

- [ ] Update Homebrew formula
- [ ] Test installation: `brew install cupertino`
- [ ] Verify: `cupertino --version`
- [ ] Announce release (if applicable)

---

## Troubleshooting

### Build Fails

```bash
# Clean and rebuild
make clean
make build
```

### Formula Test Fails

```bash
# Debug formula
brew install --verbose --debug Formula/cupertino.rb
```

### Binary Not Found After Install

```bash
# Check installation path
which cupertino
ls -la /usr/local/bin/cupertino
```

---

## See Also

- [DEVELOPMENT.md](../DEVELOPMENT.md) - Development workflow
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture
- [README.md](../README.md) - Project overview
