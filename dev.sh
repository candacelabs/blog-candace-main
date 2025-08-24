#!/bin/bash

# Build and run Hugo development server in container
# This script provides live reloading for theme development

echo "Building blog development image..."
docker build -t blog-dev . && \

echo "Starting Hugo development server..."
echo "Visit http://localhost:1313 to see your site"
echo "Press Ctrl+C to stop"

docker run -it --rm \
  -p 1313:1313 \
  -v $(pwd)/bloghome/content:/srv/content \
  -v $(pwd)/bloghome/archetypes:/srv/archetypes \
  -v $(pwd)/bloghome/assets:/srv/assets \
  -v $(pwd)/bloghome/data:/srv/data \
  -v $(pwd)/bloghome/i18n:/srv/i18n \
  -v $(pwd)/bloghome/layouts:/srv/layouts \
  -v $(pwd)/bloghome/static:/srv/static \
  -v $(pwd)/bloghome/themes:/srv/themes \
  -v $(pwd)/bloghome/hugo.toml:/srv/hugo.toml \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo server --bind 0.0.0.0 -p 1313 --buildDrafts --buildFuture --disableFastRender