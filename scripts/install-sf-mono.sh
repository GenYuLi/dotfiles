#!/usr/bin/env bash
# Install Apple SF Mono on Linux
#
# What it does
#   - Downloads SF-Mono.dmg from Apple's developer CDN (no Apple ID needed).
#   - Unpacks the nested .dmg → .pkg → Payload (gzipped cpio) using 7z.
#   - Copies the SF Mono *.otf files to ~/.local/share/fonts/SFMono/.
#   - Rebuilds the user font cache so fontconfig sees them immediately.
#
# Why this shape
#   - SF Mono is Apple-proprietary: Apple's font license permits personal
#     install for design/dev use, but forbids redistribution. So it's not
#     in dnf or nixpkgs and must be fetched per-user. The Apple CDN URL has
#     been stable for years and serves the .dmg without auth.
#   - We rely only on 7z (already installed) — no xar, no dmg2img.
#
# Usage
#   ./scripts/install-sf-mono.sh
#
# Verify after install
#   fc-match 'SF Mono'           # should resolve to a real SF-Mono*.otf
#   fc-list | grep -i "sf mono"  # lists installed weights/variants

set -euo pipefail

readonly FONT_DIR="${HOME}/.local/share/fonts/SFMono"
readonly DMG_URL="https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg"

if ! command -v 7z >/dev/null 2>&1; then
  echo "error: 7z not found — install p7zip first (sudo dnf install p7zip-plugins)" >&2
  exit 1
fi

WORKDIR="$(mktemp -d -t sf-mono-install.XXXXXX)"
trap 'rm -rf "${WORKDIR}"' EXIT

echo "==> Downloading SF Mono from Apple..."
curl -fL --progress-bar "${DMG_URL}" -o "${WORKDIR}/sf-mono.dmg"

echo "==> Extracting .dmg..."
7z x -y "${WORKDIR}/sf-mono.dmg" -o"${WORKDIR}/dmg" >/dev/null

PKG="$(find "${WORKDIR}/dmg" -name '*.pkg' -type f | head -1)"
[[ -n "${PKG}" ]] || { echo "error: no .pkg inside the .dmg"; exit 1; }

echo "==> Extracting $(basename "${PKG}")..."
7z x -y "${PKG}" -o"${WORKDIR}/pkg" >/dev/null

# The .pkg contains one or more Payload archives (gzipped cpio). Walk them
# all and keep extracting until we find .otf files.
find "${WORKDIR}/pkg" -name 'Payload' -type f | while read -r payload; do
  out="${WORKDIR}/payload-$(basename "$(dirname "${payload}")")"
  mkdir -p "${out}"
  7z x -y "${payload}" -o"${out}" >/dev/null 2>&1 || true
  # Payload extracts to a cpio archive; extract that too.
  find "${out}" -type f | while read -r inner; do
    7z x -y "${inner}" -o"${out}" >/dev/null 2>&1 || true
  done
done

mkdir -p "${FONT_DIR}"
mapfile -t otfs < <(find "${WORKDIR}" -name 'SF-Mono*.otf' -type f)
if [[ "${#otfs[@]}" -eq 0 ]]; then
  echo "error: no SF-Mono*.otf files found after extraction" >&2
  echo "       inspect ${WORKDIR} and adjust the script" >&2
  trap - EXIT
  exit 1
fi

echo "==> Installing ${#otfs[@]} font file(s) to ${FONT_DIR}..."
for f in "${otfs[@]}"; do
  cp -f "${f}" "${FONT_DIR}/"
done

echo "==> Rebuilding font cache..."
fc-cache -f "${FONT_DIR}"

echo
echo "done. Verify with:"
echo "  fc-match 'SF Mono'"
echo
echo "If you have already switched home-manager with the SF Mono fontconfig"
echo "rules in lib/default.nix, restart Heptabase / Chrome to see the change."
