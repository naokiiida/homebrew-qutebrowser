# homebrew-qutebrowser

Homebrew tap for [qutebrowser](https://www.qutebrowser.org/) with H.264/H.265 codec support.

## Why?

The upstream Homebrew cask bundles its own QtWebEngine **without** codec support, so H.264 video playback doesn't work. This formula builds against Homebrew's `qtwebengine` bottle which includes H.264/H.265 support.

The upstream cask is also [scheduled for deprecation on 2026-09-01](https://github.com/qutebrowser/qutebrowser/issues/8713) due to Gatekeeper issues.

## Install

```sh
brew install naokiiida/qutebrowser/qutebrowser
```

If you have the upstream cask installed, uninstall it first:

```sh
brew uninstall --cask qutebrowser
```

## Roadmap

- [x] CLI formula with codec support
- [ ] `.app` bundle for Dock/Spotlight integration
- [ ] Code signing & notarization
