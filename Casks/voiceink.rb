cask "voiceink" do
  version "2.1"
  sha256 "8d6b8a41ed8ac488b7fa06d1f7d979e34313ce08b3330493422a977b2912236b"

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
end
