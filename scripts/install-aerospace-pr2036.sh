#!/usr/bin/env bash
# Builds aerospace v0.19.2-Beta from source with a backport of
# https://github.com/nikitabobko/AeroSpace/pull/2036 applied. The PR fixes
# the emacs child-frame focus-jump bug
# (https://github.com/nikitabobko/AeroSpace/issues/776) by classifying
# posframe/corfu popups as non-windows.
#
# Why v0.19.2-Beta and not main (where PR 2036 was opened):
#   Upstream main (and the PR itself) require Swift 6.2+, which only ships
#   with Xcode 17. v0.19.2-Beta uses swift-tools-version 6.0 + Swift 6.1.2,
#   matching Xcode 16's bundled toolchain. We backport the 10-line detector
#   change instead of taking the whole PR.
#
# This is imperative: nix-darwin's services.aerospace is disabled (see
# configuration.nix), and the config is rendered to
# ~/.config/aerospace/aerospace.toml by home-manager. Re-run this script
# whenever you want to refresh the patched build.

set -euo pipefail

AEROSPACE_TAG="v0.19.2-Beta"
AEROSPACE_SHA="36fde5991eb92cbd422c2ce26bd521dfaec704aa"
AEROSPACE_REPO="https://github.com/nikitabobko/AeroSpace.git"
PATCH_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/patches/aerospace-emacs-child-frame-v0.19.2.patch"
WORKDIR="${HOME}/Code/aerospace-patched"

require() {
    command -v "$1" >/dev/null 2>&1 || { echo "missing dependency: $1" >&2; exit 1; }
}

require git
require brew
require python3

if [[ ! -f "$PATCH_PATH" ]]; then
    echo "patch file not found: $PATCH_PATH" >&2
    exit 1
fi

if [[ ! -d /Applications/Xcode.app ]]; then
    echo "Xcode.app not found in /Applications. Install Xcode from the App Store first." >&2
    exit 1
fi

if [[ "$(xcode-select -p)" != "/Applications/Xcode.app/Contents/Developer" ]]; then
    echo "Pointing xcode-select at Xcode.app (sudo required)..."
    sudo xcode-select -s /Applications/Xcode.app
fi

# build-shell-completion.sh syntax-checks generated completions in zsh,
# fish, and bash 5+. macOS ships zsh+bash 3.2 only.
for f in bash fish; do
    brew list "$f" >/dev/null 2>&1 || brew install "$f"
done
export PATH="$(brew --prefix bash)/bin:$(brew --prefix fish)/bin:$PATH"

# Aerospace's docs build (build-docs.sh) uses asciidoctor via bundler. The
# Gemfile pins `~> 3.0` (>=3, <4); macOS system ruby is 2.6 and brew's
# unversioned `ruby` formula is now at 4.x, so use ruby@3.3 specifically.
RUBY_FORMULA="ruby@3.3"
brew list "$RUBY_FORMULA" >/dev/null 2>&1 || brew install "$RUBY_FORMULA"
RUBY_PREFIX="$(brew --prefix "$RUBY_FORMULA")"
export PATH="${RUBY_PREFIX}/bin:$PATH"
gem install bundler >/dev/null 2>&1 || true
RUBY_GEM_BIN="$(ruby -e 'puts Gem.bindir')"
export PATH="${RUBY_GEM_BIN}:$PATH"

# .swift-version pins 6.1.2 which matches Xcode 16.4's bundled toolchain,
# so swiftly isn't strictly required — but upstream's setup.sh routes
# `swift` through `swiftly run` when swiftly is on PATH, which keeps the
# build hermetic across Xcode upgrades.
brew list swiftly >/dev/null 2>&1 || brew install swiftly
export SWIFTLY_HOME_DIR="${HOME}/.local/share/swiftly"
export SWIFTLY_BIN_DIR="${HOME}/.local/share/swiftly/bin"
export PATH="${SWIFTLY_BIN_DIR}:$PATH"
if ! swiftly list 2>/dev/null | grep -q '6\.'; then
    swiftly init --quiet-shell-followup --no-modify-profile -y >/dev/null 2>&1 || true
fi

# Aerospace's build-release.sh codesigns the .app+CLI with an identity
# named "aerospace-codesign-certificate". Upstream dev-docs/development.md
# asks devs to create this via Keychain Access GUI; we script the
# equivalent self-signed code-signing cert via openssl + security import.
CERT_NAME="aerospace-codesign-certificate"
if ! security find-certificate -c "$CERT_NAME" >/dev/null 2>&1; then
    echo "Creating self-signed code-signing cert '${CERT_NAME}'..."
    CERT_TMP="$(mktemp -d)"
    trap 'rm -rf "$CERT_TMP"' EXIT
    cat > "${CERT_TMP}/cert.conf" <<EOF
[ req ]
distinguished_name = req_dn
prompt             = no
[ req_dn ]
CN = ${CERT_NAME}
[ codesign_ext ]
basicConstraints     = critical, CA:FALSE
keyUsage             = critical, digitalSignature
extendedKeyUsage     = critical, codeSigning
EOF
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
        -keyout "${CERT_TMP}/key.pem" \
        -out    "${CERT_TMP}/cert.pem" \
        -config "${CERT_TMP}/cert.conf" \
        -extensions codesign_ext >/dev/null 2>&1
    # -legacy: OpenSSL 3 defaults to AES-256-CBC PKCS12 encryption which
    # macOS's `security` CLI can't import. The legacy flag falls back to
    # the older PBE-SHA1-3DES algorithms Apple expects. macOS `security`
    # also rejects empty PKCS12 passwords, so we use a transient placeholder.
    P12_PW="$(/usr/bin/openssl rand -hex 16)"
    openssl pkcs12 -export -legacy \
        -inkey "${CERT_TMP}/key.pem" \
        -in    "${CERT_TMP}/cert.pem" \
        -out   "${CERT_TMP}/cert.p12" \
        -passout "pass:${P12_PW}" >/dev/null 2>&1
    security import "${CERT_TMP}/cert.p12" \
        -k "${HOME}/Library/Keychains/login.keychain-db" \
        -P "${P12_PW}" \
        -T /usr/bin/codesign
fi

mkdir -p "$(dirname "$WORKDIR")"
if [[ ! -d "$WORKDIR/.git" ]]; then
    git clone "$AEROSPACE_REPO" "$WORKDIR"
fi

cd "$WORKDIR"
git fetch --tags origin
git checkout -- .  # discard any in-tree mutations from a prior run
git checkout "$AEROSPACE_SHA"

# Pre-install the swift toolchain pinned in .swift-version (6.1.2) so
# setup.sh's `swiftly run swift` doesn't bail mid-build. This is a no-op
# once the matching toolchain is cached.
swiftly install 2>&1 | tail -5

# Patch upstream's build-release.sh to skip check-uncommitted-files.sh.
# That check enforces that ./generate.sh produces no diff vs committed
# state — it works in upstream's CI which pins a specific Xcode, but our
# local generate.sh re-emits AeroSpace.xcodeproj/project.pbxproj slightly
# differently, so the check spuriously trips here.
/usr/bin/sed -i '' 's|^\./script/check-uncommitted-files\.sh$|echo "[install-aerospace-pr2036] skipping check-uncommitted-files.sh"|' build-release.sh

# Apply the PR 2036 backport patch. `git checkout -- .` above already gave
# us a clean tree at the right SHA, so always-apply is safe. (Don't try to
# detect "already applied" with `patch --dry-run -R` — BSD patch on macOS
# returns exit 0 when reverse-apply can't proceed because nothing is there
# to remove, so the check always succeeds and the patch never gets applied.)
patch -p1 < "$PATCH_PATH"

# Newer homebrew refuses casks not in a tap, so upstream's
# install-from-sources.sh (which uses `brew install-path` against a local
# .rb) no longer works. Skip it and install the built artifacts manually.
./build-release.sh

# Replace any existing /Applications/AeroSpace.app and copy the new CLI to
# /opt/homebrew/bin. This is where the brew install would have put them.
if [[ -d /Applications/AeroSpace.app ]]; then
    echo "Removing existing /Applications/AeroSpace.app..."
    rm -rf /Applications/AeroSpace.app
fi
cp -R .release/AeroSpace.app /Applications/AeroSpace.app
cp .release/aerospace /opt/homebrew/bin/aerospace
chmod +x /opt/homebrew/bin/aerospace

echo
echo "Build + install complete. Verify with:"
echo "  /opt/homebrew/bin/aerospace --version"
echo
echo "If the running aerospace is still the old nix one (or this is the first"
echo "time after disabling services.aerospace via darwin-rebuild), kick it:"
echo "  launchctl bootout gui/\$UID/org.nixos.aerospace 2>/dev/null || true"
echo "  killall AeroSpace 2>/dev/null || true"
echo "  open -a /Applications/AeroSpace.app"
echo
echo "Then in System Settings > Privacy & Security > Accessibility, ensure the"
echo "new AeroSpace.app is granted permission (toggle off + on if it looks stuck)."
