# HLS Newsletter Production Notes

This folder contains local deployment helpers for running HLS Newsletter at:

https://newsletter.hls.md

## Files

- `.env.production.example`: template for the root `.env` file used by `docker-compose.lite.yaml`.
- `Caddyfile`: HTTPS reverse proxy config. Caddy terminates TLS and proxies to HLS Newsletter on localhost port 3000.
- `docker-compose.hls.yaml`: builds your HLS image from this fork and passes production domain/security env vars into the HLS Newsletter containers.
- `backup.sh`: creates a Postgres logical dump and archives the Postgres/ClickHouse Docker volumes.

## Basic VPS Flow

1. Point DNS `A` record for `newsletter.hls.md` to the server public IP.
2. Install Docker, Docker Compose plugin, and Caddy on the server.
3. Copy `.env.production.example` to repo root as `.env` and replace all secrets.
4. Start HLS Newsletter:

```bash
docker compose -f docker-compose.lite.yaml -f deploy/hls/docker-compose.hls.yaml up -d --build
```

5. Run Caddy with this Caddyfile, or copy the site block into `/etc/caddy/Caddyfile` and reload Caddy.
6. After the first successful bootstrap, set `BOOTSTRAP=false` in `.env` and restart:

```bash
docker compose -f docker-compose.lite.yaml -f deploy/hls/docker-compose.hls.yaml up -d --force-recreate
```

## Backups

Run a backup manually from the VPS:

```bash
cd /apps/ditto
./deploy/hls/backup.sh
```

By default this writes timestamped backup folders to `/apps/ditto-backups` and removes backups older than 14 days. The script briefly stops the stack while archiving Docker volumes, then starts it again.

If the app or backup directory is different, override the paths:

```bash
APP_DIR=/apps/ditto BACKUP_ROOT=/apps/ditto-backups ./deploy/hls/backup.sh
```

To run the backup every day, add this to the root crontab with `sudo crontab -e`:

```cron
0 3 * * * APP_DIR=/apps/ditto BACKUP_ROOT=/apps/ditto-backups /apps/ditto/deploy/hls/backup.sh >> /apps/ditto/.tmp/backup.log 2>&1
```

This runs daily at 03:00 server time. Make sure `/apps/ditto/.tmp` exists before installing the cron entry:

```bash
mkdir -p /apps/ditto/.tmp
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
