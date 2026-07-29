# Repository guide

This repository contains a containerized Hugo site and its local `candace` theme.

## Architecture

- `bloghome/` is the Hugo source.
- `bloghome/themes/candace` points to the tracked theme at `themes/candace`.
- The container keeps a copy of that theme at `/themes/candace`, so the symlink resolves when `bloghome` is mounted at `/srv`.
- Generated output under `bloghome/public/` is never committed.

## Commands

- Development: `./dev.sh`
- Container build: `docker build -t candace-blog .`
- Production build: follow the build command in `README.md`
- Privacy check: `./scripts/check-public-content.sh bloghome/public`

Use `docker compose`, not the legacy `docker-compose` command.

## Public-content rules

- Keep content organization- and project-focused.
- Do not publish names, personal contact details, personal profiles, precise locations, résumés, private hostnames, network addresses, or internal service topology.
- Do not add analytics, trackers, remote fonts, or embedded third-party media without an explicit privacy review.
- Keep the site usable without client-side JavaScript.
