# mikeos-wiki

Self-hosted **Wikipedia** (Kiwix) for MikeOS — unlimited, rate-limit-free article knowledge at
`wiki.osmike.com`, on the Hetzner box (NOT Railway). OSM = *where*; Wikipedia = *what/why/story*.

**Build order is strict (see `phases.md` + the super-large-downloads best-practice):**
1. `scripts/host-download.sh` — download the ZIMs ONCE on the host (aria2 -x16 -c), verify sha256,
   into `/data/kiwix/zim/`. Run in `tmux`. **The container NEVER downloads.**
2. `docker compose up -d` — `kiwix-serve` mounts those ZIMs **read-only** and serves them.
3. Caddy `wiki.osmike.com` (bearer-gated) + grey-cloud DNS.

Docs: `CLAUDE.md` (how it works) · `phases.md` (the plan) · `SERVER-ACCESS.md` (the box).
