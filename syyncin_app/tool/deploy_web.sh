#!/usr/bin/env bash
# Build the Flutter web app for a Hostinger domain (hPanel → File Manager).
# Run from the Mac in the syyncin_app folder:
#
#   bash tool/deploy_web.sh                    # site at the domain root (public_html)
#   BASE_HREF=/syyncin/ bash tool/deploy_web.sh  # site in a sub-folder (public_html/syyncin)
#
# Output: build/web/ and build/syyncin_web.zip — upload the ZIP to public_html
# (or the sub-folder) in hPanel → File Manager and choose "Extract".
# The API address comes from lib/core/config/env.dart.
set -euo pipefail

BASE_HREF="${BASE_HREF:-/}"
cd "$(dirname "$0")/.."

echo "▶ Building Flutter web (release, base-href $BASE_HREF)…"
flutter build web --release --base-href "$BASE_HREF"

echo "▶ Zipping…"
rm -f build/syyncin_web.zip
(cd build/web && zip -qr ../syyncin_web.zip .)

echo "✓ Ready: build/syyncin_web.zip  (upload to public_html${BASE_HREF%/} and Extract)"
