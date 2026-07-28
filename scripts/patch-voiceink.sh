#!/bin/bash
# Patch an upstream VoiceInk checkout for personal distribution.
# Usage: patch-voiceink.sh <voiceink-src-dir>
# 1. Repoint Sparkle at our appcast + our EdDSA public key (otherwise the app
#    replaces itself with the author's binary within 4 hours).
# 2. Force manual code signing in the project file. Upstream bakes
#    CODE_SIGN_STYLE = Automatic and its own DEVELOPMENT_TEAM into the
#    pbxproj; xcodebuild command-line overrides of CODE_SIGN_STYLE do not
#    reliably take effect against a project-level Automatic setting (long-
#    standing xcodebuild behavior), and Automatic signing falls back to
#    ad-hoc "Sign to Run Locally" on CI runners with no signed-in Apple ID
#    account instead of failing loudly. Patching the project file is the
#    documented workaround.
# 3. Rewrite LocalBuild.xcconfig's own signing settings. The workflow builds
#    with `-xcconfig LocalBuild.xcconfig` (needed for its LOCAL_BUILD
#    compilation flag), but that file is upstream's "no developer account
#    needed" recipe: it hardcodes CODE_SIGN_IDENTITY=- (ad-hoc) and an empty
#    DEVELOPMENT_TEAM. Empirically those values win over the identical-key
#    xcodebuild command-line overrides passed by the workflow, so the
#    command-line identity/team never took effect. Patch them at the source.
# Licensing/CloudKit/keychain are handled by the LOCAL_BUILD flag +
# VoiceInk.local.entitlements at build time, not here.
set -euo pipefail

SRC="${1:?usage: patch-voiceink.sh <voiceink-src-dir>}"
PLIST="$SRC/VoiceInk/Info.plist"
PBXPROJ="$SRC/VoiceInk.xcodeproj/project.pbxproj"
XCCONFIG="$SRC/LocalBuild.xcconfig"
FEED_URL="https://raw.githubusercontent.com/AhsanFazal/homebrew-tap/master/appcast/voiceink.xml"
ED_PUBLIC_KEY="36EzINMp5KT5wUuysf0fp6ZVGrZo56lhISM4gyiRRIs="
TEAM_ID="9WAKQUB788"

PB=/usr/libexec/PlistBuddy
# Fail loudly if upstream restructures the plist — that is the update signal.
"$PB" -c "Print :SUFeedURL" "$PLIST" >/dev/null
"$PB" -c "Set :SUFeedURL $FEED_URL" "$PLIST"
"$PB" -c "Set :SUPublicEDKey $ED_PUBLIC_KEY" "$PLIST"
echo "patched: SUFeedURL -> $FEED_URL"

# Fail loudly if upstream restructures the project file.
style_count=$(grep -c 'CODE_SIGN_STYLE = Automatic;' "$PBXPROJ") || style_count=0
[ "$style_count" -gt 0 ] || { echo "no 'CODE_SIGN_STYLE = Automatic;' found in project.pbxproj — upstream structure changed" >&2; exit 1; }
team_count=$(grep -c -E 'DEVELOPMENT_TEAM = [A-Z0-9]+;' "$PBXPROJ") || team_count=0
[ "$team_count" -gt 0 ] || { echo "no 'DEVELOPMENT_TEAM = <id>;' found in project.pbxproj — upstream structure changed" >&2; exit 1; }
sed -i '' 's/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Manual;/g' "$PBXPROJ"
sed -i '' -E 's/DEVELOPMENT_TEAM = [A-Z0-9]+;/DEVELOPMENT_TEAM = "";/g' "$PBXPROJ"
echo "patched: CODE_SIGN_STYLE Automatic -> Manual ($style_count), DEVELOPMENT_TEAM cleared ($team_count)"

# Fail loudly if upstream restructures LocalBuild.xcconfig.
grep -q '^CODE_SIGN_IDENTITY = -$' "$XCCONFIG" || { echo "no 'CODE_SIGN_IDENTITY = -' found in LocalBuild.xcconfig — upstream structure changed" >&2; exit 1; }
grep -q -E '^DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*$' "$XCCONFIG" || { echo "no empty 'DEVELOPMENT_TEAM =' found in LocalBuild.xcconfig — upstream structure changed" >&2; exit 1; }
sed -i '' "s/^CODE_SIGN_IDENTITY = -\$/CODE_SIGN_IDENTITY = Apple Development/" "$XCCONFIG"
sed -i '' -E "s/^DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*\$/DEVELOPMENT_TEAM = ${TEAM_ID}/" "$XCCONFIG"
echo "patched: LocalBuild.xcconfig CODE_SIGN_IDENTITY -> Apple Development, DEVELOPMENT_TEAM -> ${TEAM_ID}"
