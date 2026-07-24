# mikeos-wiki — CLAUDE.md

## What this repo is
**MikeWiki** — a **self-hosted Wikipedia** for the MikeOS ecosystem, so MikeGuide, MikeStoryteller and
any AI Assistant can fetch as much article knowledge as they want with **zero rate limits, no
usage-policy risk, full speed, private**. Same philosophy as self-hosting OSM: *own the data for the
AI.* OSM answers **where**; Wikipedia answers **what / why / the story**.

- **Live (planned):** `https://wiki.osmike.com` — a **Kiwix** (`kiwix-serve`) container on the
  **Hetzner box** (NOT Railway). Serves rendered articles + full-text search over HTTP.
- **Runs on:** the shared OSM box (`144.76.45.114`). Server access + deploy: **`SERVER-ACCESS.md`**.
- **Plan / phases:** **`phases.md`**.

## ⛔ THE cardinal rule — download on the HOST, never in the container
Read `mikeos-architecture/docs/super-large-downloads-issues-and-howto-solve-it-best-practice.md`.
The ZIM is **~115 GB** (EN). If a container downloaded its own copy, one small init error =
re-download 115 GB **every restart**. So:
- **`scripts/host-download.sh`** pulls the ZIMs **once, on the host**, with `aria2c -x16 -c`
  (resumable, multi-connection), into **`/data/kiwix/zim/`**, and **verifies each against the
  published `.sha256`**. Run it **inside `tmux`** (multi-hour pull; an SSH drop must not kill it).
- **`docker-compose.yml`** mounts `/data/kiwix/zim` **read-only** and `kiwix-serve` **only serves
  the files already there — it never touches the network for data.** No download logic in the
  container, ever. If you refresh a ZIM: download the new dated file on the host first, then update
  the file list in `docker-compose.yml` + `scripts/host-download.sh`.

## The ZIMs (dated monthly)
`wikipedia_en_all_maxi_2026-02.zim` (~115 GB, full English incl. images) ·
`wikipedia_sv_all_maxi_2026-04.zim` (Swedish) · `wikipedia_fr_all_maxi_2026-05.zim` (French).
`all_maxi` = with images; `all_nopic` ≈ half the size if we ever need to save space (Guide already
gets images from OSM/photos). Mirror: `https://download.kiwix.org/zim/wikipedia/`.

## Serving + how other services use it
`kiwix-serve` on `172.17.0.1:8083`, fronted by Caddy at `wiki.osmike.com`, **bearer-gated**
(`Authorization: Bearer $WIKI_TOKEN`) so it's *our* knowledge base, not a public mirror the whole
internet scrapes. Key endpoints:
- `GET /search?books.name=wikipedia_en_all_maxi&pattern=<q>&pageLength=10` → full-text search (JSON/HTML).
- `GET /suggest?content=<book>&term=<q>` → title suggestions.
- `GET /content/<book>/A/<Article_Title>` → the rendered article HTML (parse for prose).
- `GET /catalog/v2/entries` → the list of books (their exact `name`s).
**Integration (later phase):** repoint **guide-cloud** + **storyteller-cloud** from
`en.wikipedia.org/api/rest_v1/...` to `wiki.osmike.com` (send the bearer) — exactly how we cut over
OSM. That kills the rate-limited public Wikipedia calls.

## Files
`scripts/host-download.sh` (the host downloader — aria2 + sha256) · `docker-compose.yml`
(kiwix-serve, read-only mount) · `Caddyfile.snippet` (the `wiki.osmike.com` block) · `phases.md`
· `SERVER-ACCESS.md`.

## House rules
- **Container is a server, not a downloader** — data comes in via a read-only mount.
- **Idempotent + resumable + checksum-verified** beats "fast path that assumes success."
- Monitor the **real public endpoint** (`https://wiki.osmike.com/...`), not the internal `:8083`.
- **Do NOT disturb the OSM stack** on the box (`mikeos-*` containers + tmux imports). Mind disk
  headroom (the OSM imports are still growing — check `df -h /data` before a 115 GB pull).
- No paid services. Zero cost.
