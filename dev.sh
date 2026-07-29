#!/usr/bin/env bash

set -euo pipefail

BLOG_PORT="${BLOG_PORT:-1314}"

docker build -t candace-blog:dev .

echo "Candace Labs blog: http://localhost:${BLOG_PORT}"

docker run --interactive --tty --rm \
  --user "$(id -u):$(id -g)" \
  --publish "${BLOG_PORT}:1313" \
  --volume "$PWD/bloghome:/srv" \
  candace-blog:dev \
  server \
  --bind 0.0.0.0 \
  --port 1313 \
  --buildDrafts \
  --buildFuture \
  --disableFastRender \
  --noBuildLock \
  --environment development
