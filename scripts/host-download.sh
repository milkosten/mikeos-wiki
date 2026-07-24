#!/usr/bin/env bash
# host-download.sh — pull the Wikipedia ZIMs ONCE onto the host, verify sha256, ready to mount RO.
#
# Follows mikeos-architecture/docs/super-large-downloads-issues-and-howto-solve-it-best-practice.md:
#   • aria2 -x16 -c  → resumable, multi-connection (~11x faster than single-stream curl)
#   • verify against the PUBLISHED .sha256 (authoritative, one disk read — not a slow decompress)
#   • NO `curl --retry` + `-C -` footgun.  Container mounts these READ-ONLY and NEVER downloads.
#   • RUN INSIDE tmux so a dropped SSH can't kill a multi-hour pull:  tmux new -s wiki
set -u
BASE="https://download.kiwix.org/zim/wikipedia"
DEST="/data/kiwix/zim"
# Dated monthly — bump these when refreshing (and update docker-compose.yml's file list to match).
ZIMS="
wikipedia_en_all_maxi_2026-02.zim
wikipedia_sv_all_maxi_2026-04.zim
wikipedia_fr_all_maxi_2026-05.zim
"
mkdir -p "$DEST"; cd "$DEST" || exit 1
echo "== free space before =="; df -h "$DEST" | tail -1
for z in $ZIMS; do
  echo; echo "=== downloading $z ==="
  # resumable, multi-connection; safe to Ctrl-C / re-run. aria2 follows the lb->mirror redirects.
  aria2c -x16 -s16 -c --file-allocation=none --auto-file-renaming=false \
         --console-log-level=warn --summary-interval=30 \
         -d "$DEST" -o "$z" "$BASE/$z" || { echo "!! aria2 failed for $z (re-run to resume)"; continue; }
  echo "-- verifying $z against published sha256 --"
  exp=$(curl -fsSL "$BASE/$z.sha256" | grep -oiE '[0-9a-f]{64}' | head -1)
  got=$(sha256sum "$DEST/$z" | awk '{print $1}')
  if [ -n "$exp" ] && [ "$exp" = "$got" ]; then
    echo "OK   $z  sha256 verified ($got)"
  else
    echo "FAIL $z  sha256 MISMATCH  exp=$exp got=$got  (delete + re-run)"
  fi
done
echo; echo "== all done — files in $DEST =="; ls -la "$DEST"
echo "Next: on the box, 'cd /root/mikeos-wiki && docker compose up -d' (serves these; never downloads)."
