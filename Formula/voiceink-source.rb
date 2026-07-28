class VoiceinkSource < Formula
  desc "Voice-to-text app, built locally from source (side door; cask is primary)"
  homepage "https://tryvoiceink.com/"
  url "https://github.com/Beingpax/VoiceInk/archive/refs/tags/v2.1.tar.gz"
  sha256 "82e7f4f1ced900c52ed943e543de43a50cc04994350dba2b06df1bac70daee1c"
  license "GPL-3.0-only"
  head "https://github.com/Beingpax/VoiceInk.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "cmake" => :build
  depends_on xcode: :build
  depends_on macos: :sonoma

  # Bump to latest whisper.cpp release when bumping VoiceInk; CI resolves
  # dynamically, this formula pins.
  resource "whisper-cpp" do
    url "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v1.9.1.tar.gz"
    sha256 "147267177eef7b22ec3d2476dd514d1b12e160e176230b740e3d1bd600118447"
  end

  # SPM package resolution git-clones each dependency; Homebrew denies all
  # network access during `install` by default.
  allow_network_access! :build

  def install
    whisper_src = buildpath/"deps/whisper.cpp"
    whisper_src.mkpath
    resource("whisper-cpp").stage(whisper_src)
    cd whisper_src do
      system "bash", tap.path/"scripts/build-xcframework-macos-only.sh"
    end

    # Project references the framework at $(HOME)/VoiceInk-Dependencies/...;
    # repoint at our staged copy instead of faking HOME.
    inreplace "VoiceInk.xcodeproj/project.pbxproj",
              "$(HOME)/VoiceInk-Dependencies/whisper.cpp/build-apple/whisper.xcframework",
              "#{whisper_src}/build-apple/whisper.xcframework"

    system "bash", tap.path/"scripts/patch-voiceink.sh", buildpath.to_s

    args = [
      "-project", "VoiceInk.xcodeproj",
      "-scheme", "VoiceInk",
      "-configuration", "Release",
      "-derivedDataPath", (buildpath/"derived").to_s,
      "-clonedSourcePackagesDirPath", (buildpath/"spm-cache").to_s,
      "-xcconfig", "LocalBuild.xcconfig",
      "CODE_SIGN_STYLE=Manual",
      "CODE_SIGN_IDENTITY=Apple Development",
      "DEVELOPMENT_TEAM=9WAKQUB788",
      "CODE_SIGNING_REQUIRED=YES",
      "CODE_SIGNING_ALLOWED=YES",
      "CODE_SIGN_ENTITLEMENTS=#{buildpath}/VoiceInk/VoiceInk.local.entitlements",
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) LOCAL_BUILD"
    ]

    # Upstream's tag itself carries stale version metadata (author bumps
    # MARKETING_VERSION/CURRENT_PROJECT_VERSION at build time, not before
    # tagging) — v2.1's pbxproj still says 2.0/205. Override for stable
    # builds only; HEAD tracks main's pbxproj as-is (it's dev-channel by
    # definition, no fixed version to assert).
    if build.stable?
      parts = version.to_s.split(".").map(&:to_i)
      project_version = (parts[0] * 100) + ((parts[1] || 0) * 10) + (parts[2] || 0)
      args += ["MARKETING_VERSION=#{version}", "CURRENT_PROJECT_VERSION=#{project_version}"]
    end

    xcodebuild(*args, "build")

    app = buildpath/"derived/Build/Products/Release/VoiceInk.app"

    # Mirror CI's hard gate: refuse to install an ad-hoc-signed build.
    # Upstream's pbxproj (CODE_SIGN_STYLE=Automatic) and LocalBuild.xcconfig
    # (CODE_SIGN_IDENTITY=-) both silently shadow the identical-key
    # xcodebuild overrides above unless patch-voiceink.sh has already fixed
    # them; catch a regression here instead of shipping an ad-hoc build.
    identity = shell_output("codesign -dv #{app} 2>&1")
    unless identity.match?(/^TeamIdentifier=9WAKQUB788$/)
      odie "app is not signed with team 9WAKQUB788 (ad-hoc fallback?):\n#{identity}"
    end

    prefix.install app
  end

  def caveats
    <<~EOS
      Side-door source build. The cask (brew install --cask voiceink) is the
      primary install; do not use both blindly — each wants to own
      /Applications/VoiceInk.app.

      Deploy this build:
        ditto #{prefix}/VoiceInk.app /Applications/VoiceInk.app

      Signing uses your local "Apple Development" cert (team 9WAKQUB788).

      xcodebuild's own SPM package-resolution sandbox cannot nest inside
      Homebrew's build sandbox on a default-prefix install (macOS refuses a
      second sandbox_apply in an already-sandboxed process); there is no
      `--no-sandbox` install flag in current Homebrew, and
      $HOMEBREW_AVOID_NESTED_SANDBOXING requires a non-default prefix. If
      `brew install` fails with "Could not resolve package dependencies:
      sandbox-exec: sandbox_apply: Operation not permitted", this formula
      cannot build under this Homebrew's sandbox; see
      https://github.com/orgs/Homebrew/discussions/59.

      HEAD builds will offer "updates" to the latest release build via the
      in-app updater; ignore it, or uninstall/reinstall --HEAD to stay on
      main.
    EOS
  end

  test do
    app = prefix/"VoiceInk.app"
    assert_path_exists app/"Contents/MacOS/VoiceInk"
    system "codesign", "--verify", "--strict", app.to_s
    identity = shell_output("codesign -dv #{app} 2>&1")
    assert_match(/^TeamIdentifier=9WAKQUB788$/, identity)
    feed = shell_output("/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' #{app}/Contents/Info.plist").strip
    assert_match "AhsanFazal/homebrew-tap", feed
  end
end
