cask "voiceink" do
  version "2.1"
  sha256 "4824fec8618eb18790e64af38da1809fc6e05ea509dce0b3080678fd3f296476"

  url "https://github.com/AhsanFazal/homebrew-tap/releases/download/voiceink-v#{version}/VoiceInk.dmg",
      verified: "github.com/AhsanFazal/homebrew-tap/"
  name "VoiceInk"
  desc "Voice to text app (personal build: licensed, own update feed)"
  homepage "https://tryvoiceink.com/"

  livecheck do
    url "https://github.com/Beingpax/VoiceInk"
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "VoiceInk.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/VoiceInk.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/com.prakashjoshipax.VoiceInk",
    "~/Library/Application Support/VoiceInk",
    "~/Library/Caches/com.prakashjoshipax.VoiceInk",
    "~/Library/HTTPStorages/com.prakashjoshipax.VoiceInk",
    "~/Library/Preferences/com.prakashjoshipax.VoiceInk.plist",
    "~/Library/Saved Application State/com.prakashjoshipax.VoiceInk.savedState",
  ]

  caveats <<~CAVEATS
    Personal build of VoiceInk, built from unmodified upstream source
    (github.com/Beingpax/VoiceInk, GPL-3.0) with upstream's own
    local-build mode. Build scripts are attached to each release.

    Updates arrive in-app (Sparkle); brew upgrade also works.

    First launch asks once for microphone, accessibility, and
    screen-recording permissions; grants should persist across
    updates.

    Always use the fully-qualified name (ahsanfazal/tap/voiceink) —
    homebrew/cask ships an unrelated voiceink cask.
  CAVEATS
end
