# homebrew-tap

Personal Homebrew tap.

```sh
brew tap ahsanfazal/tap
```

## Packages

| Package | Type | Install |
|---------|------|---------|
| [VoiceInk](https://tryvoiceink.com/) | Cask | `brew install --cask ahsanfazal/tap/voiceink` |
| voiceink-source | Formula | Source build of VoiceInk (`--HEAD` supported); see formula caveats |

Use the fully-qualified names shown above — `homebrew/cask` ships an
unrelated `voiceink` cask that a bare name would resolve to.

## Updates

Apps update themselves in-app (Sparkle). `brew upgrade` works as well; the
two don't conflict.

On first launch, macOS asks once for microphone, accessibility, and
screen-recording permissions. Grants persist across updates.

## Source

VoiceInk is built from the unmodified upstream source of
[Beingpax/VoiceInk](https://github.com/Beingpax/VoiceInk) (GPL-3.0) at each
release tag, using upstream's own local-build mode. The build scripts are
attached to every [release](../../releases); together with the upstream tag
tarball they are the complete corresponding source. Not affiliated with the
upstream author.
