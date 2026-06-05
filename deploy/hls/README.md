# HLS Dittofeed Production Notes

This folder contains local deployment helpers for running Dittofeed at:

https://newletter.hls.md

If the intended subdomain is `newsletter.hls.md`, replace `newletter.hls.md` in both files.

## Files

- `.env.production.example`: template for the root `.env` file used by `docker-compose.lite.yaml`.
- `Caddyfile`: HTTPS reverse proxy config. Caddy terminates TLS and proxies to Dittofeed on localhost port 3000.
- `docker-compose.hls.yaml`: passes HLS production domain/security env vars into the Dittofeed containers.

## Basic VPS Flow

1. Point DNS `A` record for `newletter.hls.md` to the server public IP.
2. Install Docker, Docker Compose plugin, and Caddy on the server.
3. Copy `.env.production.example` to repo root as `.env` and replace all secrets.
4. Start Dittofeed:

```bash
docker compose -f docker-compose.lite.yaml -f deploy/hls/docker-compose.hls.yaml up -d
```

5. Run Caddy with this Caddyfile, or copy the site block into `/etc/caddy/Caddyfile` and reload Caddy.
6. After the first successful bootstrap, set `BOOTSTRAP=false` in `.env` and restart:

```bash
docker compose -f docker-compose.lite.yaml -f deploy/hls/docker-compose.hls.yaml up -d --force-recreate
```

## Branding

For the simple static logo/favicon replacement, replace these files before building your own image or mount equivalent files into the running container:

- `packages/dashboard/public/logo.png`
- `packages/dashboard/public/favicon.png`
- `packages/dashboard/public/favicon.ico`

The current `logo.png` is a wide PNG. Use a transparent PNG with similar proportions for the least layout risk.

## Production Exposure Warning

The upstream `docker-compose.lite.yaml` publishes internal service ports such as Postgres, ClickHouse, and Temporal. Before exposing this server publicly, restrict inbound firewall traffic to only `80`, `443`, and your SSH port, or edit/comment the internal dependency `ports` blocks in `docker-compose.lite.yaml`.

Do not leave database or ClickHouse ports open to the internet.
