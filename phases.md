# MikeWiki — phases

Goal: a self-hosted Wikipedia at `wiki.osmike.com` giving the whole ecosystem unlimited article
knowledge (no rate limits). Built strictly **download-first** (host download → verify → mount RO →
serve), per `super-large-downloads-issues-and-howto-solve-it-best-practice.md`.

## P1 — Download the ZIMs onto the host (the long pole; do FIRST) ← current
- On the box, in **`tmux new -s wiki`**, run **`scripts/host-download.sh`**:
  `aria2c -x16 -c` the EN (~115 GB) + SV + FR ZIMs into `/data/kiwix/zim/`, **verify each `.sha256`**.
- Resumable — a dropped link / Ctrl-C just re-runs and continues. **Nothing else depends on this
  finishing except P2.** Watch: `df -h /data`, `tmux attach -t wiki`.
- **Done when:** all ZIMs present in `/data/kiwix/zim/` and sha256-verified.

## P2 — Serve (kiwix-serve container) — ONLY after P1 verifies
- `cd /root/mikeos-wiki && docker compose up -d` → `kiwix-serve` mounts `/data/kiwix/zim` **read-only**
  and serves the files that already exist. **No download in the container.**
- Add the `wiki.osmike.com` block (`Caddyfile.snippet`) to `/root/mikeos-osm/Caddyfile`, set
  `WIKI_TOKEN` in Caddy's env, `docker restart mikeos-caddy`.
- Cloudflare **A + AAAA** `wiki.osmike.com` → the box, **grey-cloud** (Caddy owns TLS), via the CF API.
- **Verify the real public endpoint:** `curl -H "Authorization: Bearer $WIKI_TOKEN"
  https://wiki.osmike.com/search?...&pattern=Nice` returns results; an article `/content/.../A/Nice`
  returns HTML. (Health-check the public URL, not `:8083`.)

## P3 — Wire the ecosystem to it
- Repoint **guide-cloud** + **storyteller-cloud** from `en.wikipedia.org/api/rest_v1/...` →
  `wiki.osmike.com` (send the bearer). Add a tiny client (search → pick best article → fetch prose)
  mirroring how they use the public API today. Kills the rate-limited public Wikipedia calls.
- Add SV/FR lookups for local content where relevant.

## P4 (optional, later) — AI-grade retrieval (the "geo-AI" upgrade)
- Extract clean article **prose** from the ZIMs (libzim/zimdump) → a **semantic index** (Postgres FTS
  or Meilisearch + embeddings) exposed as `/knowledge/search?q=` for **RAG**, so the free GPU gets
  clean relevant passages instead of scraped HTML. (Same idea as the planned `mikeos-geo` layer over
  OSM.) Separate service; the ZIMs on disk are the source.

## Refresh (monthly, when wanted)
Bump the dated filenames in `scripts/host-download.sh` **and** the file list in `docker-compose.yml`,
re-run the host download (aria2 resumes/adds), then `docker compose up -d`. Delete the old dated ZIM
to reclaim space once the new one verifies.
