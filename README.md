# homebrew-tap

Personally-built, personally-signed [VoiceInk](https://tryvoiceink.com/),
distributed through my own Homebrew tap with my own Sparkle update feed.

**Not affiliated with the upstream author.** VoiceInk upstream is
[Beingpax/VoiceInk](https://github.com/Beingpax/VoiceInk) (GPL-3.0). Builds
here use the upstream project's own author-sanctioned `LOCAL_BUILD`
source-build path (a licensed, no-purchase local build mode upstream itself
ships) — not a crack or a bypass. Every release on this repo attaches the
exact patch scripts used to build it. The unmodified upstream source itself
isn't re-hosted here — it's upstream's own tag tarball, at
`github.com/Beingpax/VoiceInk/archive/refs/tags/<tag>.tar.gz` (browse tags:
[Beingpax/VoiceInk/tags](https://github.com/Beingpax/VoiceInk/tags)). GPLv3
permits pointing to where the source is available rather than re-bundling
it; the tag tarball plus the attached patch scripts together are the
complete corresponding source for what's shipped here. The build pipeline
itself lives in a separate, private repo (CI, signing secrets).

## Install

```sh
brew tap ahsanfazal/tap
brew install --cask ahsanfazal/tap/voiceink
```

**Always use the fully-qualified name, `ahsanfazal/tap/voiceink`.** Homebrew
also has an official, unrelated `voiceink` cask in `homebrew/cask`. A bare
`brew install voiceink` (or `upgrade`/`reinstall` without the tap prefix)
resolves to that one instead — a different binary, different signing
identity, different update feed — with no warning that it picked the wrong
one.

## Updates

The app self-updates via Sparkle, usually within hours of a new release
being published here. `brew upgrade` also works for version bumps and is
safe to run at any time — Homebrew and Sparkle updates don't conflict; worst
case `brew upgrade` reinstalls a version Sparkle already delivered, which is
harmless.

**First launch after install:** macOS will re-prompt for microphone,
accessibility, and screen-recording permissions once, since this is a
different code-signing identity than any prior install of VoiceInk you may
have had. Grant them when prompted. After that first grant, permissions
should persist across future updates — macOS keys TCC grants to the app's
signing identity, and this build keeps a stable one across releases.

## voiceink-source (advanced)

`Formula/voiceink-source.rb` builds VoiceInk from source locally, including
a `--HEAD` variant that tracks upstream's `main` branch. It exists as a
side door for building from a specific commit or testing pre-release
changes — the cask above is the primary, recommended install path.

It currently **cannot complete `brew install` on a default-prefix Homebrew
install** (the common case on Apple Silicon Macs): `xcodebuild`'s own Swift
Package Manager sandbox can't nest inside Homebrew's own build sandbox, a
known Homebrew/Xcode limitation, not a bug in this formula — seven distinct
workarounds were tried and falsified, so there is no `brew install`-side
fix. See the formula's own `caveats` (shown after a failed or attempted
install) for the full explanation and a link to the upstream Homebrew
discussion.

For a manual, brew-free build of `main`, skip `brew` entirely and use
upstream's own tooling plus this tap's patch script:

```sh
git clone https://github.com/Beingpax/VoiceInk.git
cd VoiceInk
bash /path/to/homebrew-tap/scripts/patch-voiceink.sh "$PWD"   # Sparkle repoint + signing patches, same as CI
make local                                                     # upstream's own ad-hoc local-build target, no Apple Developer cert required
```

## Uninstall

```sh
brew uninstall --cask ahsanfazal/tap/voiceink
brew uninstall --zap --cask ahsanfazal/tap/voiceink
```

The plain `uninstall` removes the app; `--zap` also removes saved state,
preferences, caches, and application support data (transcription history,
dictionary, models). Use the qualified name here too, for the same reason as
install — an unqualified `brew uninstall --cask voiceink` risks operating on
the wrong cask's receipt.
