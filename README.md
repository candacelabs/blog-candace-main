# Candace Labs blog

A small Hugo site for public notes from [Candace Labs](https://github.com/candacelabs). The site is intentionally static, CSS-only, and free of personal profiles, analytics, and third-party font requests.

## What is here

- `bloghome/content/` — published pages and notes
- `themes/candace/` — the hand-drawn field-notebook Hugo theme
- `bloghome/hugo.toml` — navigation, metadata, and selected projects
- `scripts/check-public-content.sh` — a privacy regression check for generated output

The container pins Hugo `0.164.0` and verifies the official release checksum.

## Develop locally

Docker is the only prerequisite:

```bash
./dev.sh
```

Open <http://localhost:1314>. Set `BLOG_PORT` to use a different host port.

## Build and check

```bash
docker build -t candace-blog .
mkdir -p bloghome/public
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/bloghome:/srv" \
  candace-blog \
  --minify --gc --cleanDestinationDir --destination /srv/public
./scripts/check-public-content.sh bloghome/public
```

The generated site is written to `bloghome/public/`, which is intentionally ignored by Git.

## Privacy boundary

Public content should describe projects and reusable technical decisions, not individuals or private infrastructure. The checker rejects common personal-contact, profile, document-sharing, and private-network patterns in the generated HTML.

The site deliberately ships without client-side JavaScript or third-party analytics. Links to public Candace Labs repositories are the only social/project identity exposed by default.

## Server integration

Pull requests build and scan the site without deployment. A successful push to
`main` rebuilds and rechecks the exact revision, packages only the generated
public output into an immutable runtime image, and sends it to the constrained
production deployer over Tailscale.

The one-time host and GitHub environment setup lives in the private server
repository. No production hostname, account, key, or network address is stored
in this public repository.
